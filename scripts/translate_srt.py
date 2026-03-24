 #!/usr/bin/env python3
"""
═══════════════════════════════════════════════════════════════════════════════
TRADUCTOR DE SUBTÍTULOS SRT CON MLX - VERSIÓN 3.0 (CORREGIDA)
═══════════════════════════════════════════════════════════════════════════════
"""

import sys
import argparse
import re
from pathlib import Path
from typing import List, Dict

try:
    from mlx_lm import load
except ImportError:
    print("❌ Error: mlx-lm no está instalado")
    print("   Instala con: pip install mlx-lm")
    sys.exit(1)


def parse_srt(srt_content: str) -> List[Dict[str, str]]:
    """Parsea contenido SRT en lista estructurada."""
    subtitle_pattern = r'(\d+)\n(\d{2}:\d{2}:\d{2},\d{3}) --> (\d{2}:\d{2}:\d{2},\d{3})\n(.*?)(?=\n\n|\Z)'
    matches = re.findall(subtitle_pattern, srt_content, re.DOTALL)
    
    subtitles = []
    for idx, start, end, text in matches:
        subtitles.append({
            'index': idx,
            'start': start,
            'end': end,
            'text': text.strip()
        })
    
    return subtitles


def translate_batch(
    texts: List[str], 
    source_lang: str, 
    model,
    tokenizer,
    temperature: float = 0.3,
    verbose: bool = False
) -> List[str]:
    """Traduce un lote de textos usando MLX con tokenizador."""
    
    batch_text = "\n---\n".join(texts)
    
    prompt = f"""Eres traductor profesional de subtítulos. Tu tarea ÚNICA es traducir de {source_lang} a español.

INSTRUCCIONES CRÍTICAS:
- Traduce SOLO el texto de los subtítulos
- NO añadas notas, explicaciones, comentarios ni nada adicional
- Respeta puntación y estructura original
- Devuelve el texto traducido en EXACTAMENTE el MISMO ORDEN
- Separa traducciones con --- (igual que la entrada)
- Si no entiends algo, traduce lo más cercano

TEXTOS A TRADUCIR (separados por ---):
{batch_text}

TRADUCCIONES (SOLO TEXTO TRADUCIDO, SEPARADAS POR ---, SIN COMENTARIOS):"""

    try:
        import mlx.core as mx
        
        # Tokeniza el prompt
        tokens = tokenizer.encode(prompt)
        tokens_array = mx.array([tokens])  # Crea batch de 1
        
        # Genera token a token
        output_tokens = []
        max_tokens = 2000
        
        for i in range(max_tokens):
            # Obtén logits del modelo
            logits = model(tokens_array)
            
            # Toma el último token y última posición
            next_logits = logits[0, -1, :]
            
            # Aplica temperature
            if temperature > 0:
                next_logits = next_logits / temperature
            
            # Toma el token con mayor probabilidad (greedy)
            next_token_id = mx.argmax(next_logits)
            next_token = int(next_token_id)
            
            # Añade a salida
            output_tokens.append(next_token)
            
            # Detén si es token de final
            if next_token == tokenizer.eos_token_id:
                break
            
            # Prepara siguiente entrada: concatena token nuevo
            new_token_array = mx.array([[next_token]])
            tokens_array = mx.concatenate([tokens_array, new_token_array], axis=1)
        
        # Decodifica resultado
        response_text = tokenizer.decode(output_tokens)
        
        if verbose:
            print(f"\n[DEBUG] Tokens generados: {len(output_tokens)}")
            print(f"[DEBUG] Preview: {response_text[:200]}...")
        
        # Separa por delimitador
        translations = response_text.split("---")
        cleaned = [t.strip() for t in translations if t.strip()]
        
        return cleaned
        
    except Exception as e:
        if verbose:
            print(f"\n[DEBUG ERROR] {type(e).__name__}: {e}")
        raise


def write_srt(subtitles: List[Dict[str, str]], output_path: str) -> None:
    """Escribe lista de subtítulos en formato SRT."""
    with open(output_path, 'w', encoding='utf-8') as f:
        for sub in subtitles:
            f.write(f"{sub['index']}\n")
            f.write(f"{sub['start']} --> {sub['end']}\n")
            f.write(f"{sub['text']}\n\n")


def main():
    """Función principal."""
    
    parser = argparse.ArgumentParser(
        description='🎬 Traductor de subtítulos SRT con MLX local - Español',
        formatter_class=argparse.RawDescriptionHelpFormatter
    )
    
    parser.add_argument('input_file', help='Archivo .srt a traducir')
    parser.add_argument('--lang', default='inglés', help='Idioma de origen')
    parser.add_argument('--batch-size', type=int, default=8, help='Subtítulos por lote')
    parser.add_argument('--temp', type=float, default=0.3, help='Temperature (0.0-1.0)')
    parser.add_argument('--output', help='Archivo salida')
    parser.add_argument('--verbose', action='store_true', help='Mostrar debug')
    
    args = parser.parse_args()
    
    # VALIDACIONES
    input_path = Path(args.input_file)
    
    if not input_path.exists():
        print(f"❌ Error: Archivo '{args.input_file}' no encontrado")
        sys.exit(1)
    
    if not (1 <= args.batch_size <= 20):
        print(f"⚠️  batch-size debe estar entre 1-20, usando 8")
        args.batch_size = 8
    
    if not (0.0 <= args.temp <= 1.0):
        print(f"⚠️  temperature debe estar entre 0.0-1.0, usando 0.3")
        args.temp = 0.3
    
    if not args.output:
        args.output = input_path.stem + "_es.srt"
    
    # LECTURA
    print(f"\n📖 LEYENDO: {args.input_file}")
    try:
        with open(input_path, 'r', encoding='utf-8') as f:
            srt_content = f.read()
    except UnicodeDecodeError:
        print(f"❌ Error: Archivo no es UTF-8")
        sys.exit(1)
    
    subtitles = parse_srt(srt_content)
    print(f"✅ Se encontraron {len(subtitles)} subtítulos")
    
    if not subtitles:
        print(f"❌ Error: No se encontraron subtítulos")
        sys.exit(1)
    
    # CARGAR MODELO
    print(f"\n🤖 CARGANDO MODELO: Mistral 7B Instruct (4-bit cuantizado)")
    
    try:
        # load() retorna TUPLA: (model, tokenizer)
        model, tokenizer = load("mlx-community/Mistral-7B-Instruct-v0.3-4bit")
        print(f"✅ Modelo y tokenizador cargados exitosamente")
    except Exception as e:
        print(f"❌ Error: {e}")
        if args.verbose:
            import traceback
            traceback.print_exc()
        sys.exit(1)
    
    # TRADUCCIÓN
    print(f"\n⏳ TRADUCIENDO ({args.lang} → español)")
    print(f"   Lote size: {args.batch_size} | Temperature: {args.temp}")
    print(f"   Batches totales: {(len(subtitles) + args.batch_size - 1) // args.batch_size}\n")
    
    translated_subtitles = []
    total_batches = (len(subtitles) + args.batch_size - 1) // args.batch_size
    
    for batch_num, i in enumerate(range(0, len(subtitles), args.batch_size), 1):
        batch = subtitles[i:i+args.batch_size]
        texts_to_translate = [sub['text'] for sub in batch]
        
        start_idx = i + 1
        end_idx = min(i + args.batch_size, len(subtitles))
        
        print(f"   [{batch_num}/{total_batches}] Subtítulos {start_idx}-{end_idx}...", end=" ", flush=True)
        
        try:
            translations = translate_batch(
                texts_to_translate, 
                args.lang, 
                model,
                tokenizer,
                temperature=args.temp,
                verbose=args.verbose
            )
            
            for j, sub in enumerate(batch):
                if j < len(translations):
                    sub['text'] = translations[j]
                translated_subtitles.append(sub)
            
            print("✅")
            
        except Exception as e:
            print(f"❌\n   Error: {e}")
            if args.verbose:
                import traceback
                traceback.print_exc()
            sys.exit(1)
    
    # ESCRIBIR
    print(f"\n💾 ESCRIBIENDO: {args.output}")
    try:
        write_srt(translated_subtitles, args.output)
        print(f"✅ ¡Completado!")
    except Exception as e:
        print(f"❌ Error: {e}")
        sys.exit(1)
    
    print(f"\n{'='*80}")
    print(f"📊 RESUMEN:")
    print(f"   Entrada:  {args.input_file}")
    print(f"   Salida:   {args.output}")
    print(f"   Idioma:   {args.lang} → español")
    print(f"   Subtítulos: {len(translated_subtitles)}")
    print(f"{'='*80}\n")


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print(f"\n\n⚠️  Interrumpido")
        sys.exit(1)
    except Exception as e:
        print(f"\n\n❌ Error: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
