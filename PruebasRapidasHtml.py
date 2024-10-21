import requests
from bs4 import BeautifulSoup, NavigableString
import re
from transformers import pipeline
import random
import os

# Configuración
url_base = 'https://doku.plexus.es'
username = 'victor.jimenezvaquer'
password = 'XV(s98v%ofMj)7'
pagina_cliente = '236_telefonica_producto'

# Añade esta variable al principio del script, junto con las otras configuraciones
carpeta_salida = r"C:\Users\victor.jimenezvaquer\Desktop\PROYECTOS_PLEXUS\PROYECTO_WIKI\JSONS\007 - Conceillo De Santiago"

# Crear una sesión para mantener las cookies
session = requests.Session()

def autenticar():
    login_url = f'{url_base}/doku.php'
    login_data = {
        'do': 'login',
        'u': username,
        'p': password
    }
    try:
        response = session.post(login_url, data=login_data)
        return response.status_code == 200
    except Exception as e:
        print(f"Error durante la autenticación: {str(e)}")
        return False

def obtener_contenido_html(page_id):
    url = f'{url_base}/doku.php?id={page_id}&do=export_xhtml'
    try:
        response = session.get(url)
        return response.text
    except Exception as e:
        print(f"Error al obtener el contenido HTML de {page_id}: {str(e)}")
        return None

def obtener_todas_las_paginas(pagina_inicio):
    paginas = set()
    por_procesar = [pagina_inicio]

    while por_procesar:
        page_id = por_procesar.pop(0)
        if page_id not in paginas:
            paginas.add(page_id)
            
            html_content = obtener_contenido_html(page_id)
            if html_content:
                soup = BeautifulSoup(html_content, 'html.parser')
                links = soup.select('a.wikilink1')
                for link in links:
                    href = link.get('href', '')
                    if 'doku.php?id=' in href:
                        nueva_pagina = href.split('id=')[-1]
                        if nueva_pagina not in paginas:
                            por_procesar.append(nueva_pagina)

    return list(paginas)

def clean_dokuwiki_content(html_content):
    soup = BeautifulSoup(html_content, 'html.parser')
    
    main_content = soup.find('div', class_='dokuwiki export')
    if not main_content:
        return "No se encontró el contenido principal"
    
    cleaned_html = "<body>\n"
    
    title = main_content.find('h1')
    if title:
        cleaned_html += f'<section style="margin: 20px 0; padding: 15px; border: 1px solid #e3e3e3; border-radius: 4px;">\n'
        cleaned_html += f'<h1 style="font-size: 2em; color: #333;">{title.text.strip()}</h1>\n'
        cleaned_html += f'</section>\n'
    
    for section in main_content.find_all(['div', 'h2', 'h3'], class_=re.compile('(sectionedit|bs-wrap bs-callout)')):
        if section.name in ['h2', 'h3']:
            cleaned_html += process_section(section)
        else:
            section_title = section.find(['h2', 'h3', 'h4'])
            if section_title:
                cleaned_html += process_section(section, section_title)
    
    cleaned_html += "</body>"
    return cleaned_html

def process_section(section, section_title=None):
    section_html = f'<section style="margin: 20px 0; padding: 15px; border: 1px solid #e3e3e3; border-radius: 4px;">\n'
    
    if section_title:
        section_html += f'<h2 style="font-size: 1.5em; color: #333;">{section_title.text.strip()}</h2>\n'
    elif section.name in ['h2', 'h3']:
        section_html += f'<h2 style="font-size: 1.5em; color: #333;">{section.text.strip()}</h2>\n'
    
    section_html += f'<div style="margin-top: 10px;">\n'
    
    content = section.find_next_sibling('div') if section.name in ['h2', 'h3'] else section
    if content:
        section_html += process_content(content)
    
    section_html += f'</div>\n</section>\n'
    return section_html

def obtener_titulo_pagina(html_content):
    soup = BeautifulSoup(html_content, 'html.parser')
    titulo = soup.find('h1')
    if titulo:
        return titulo.text.strip()
    else:
        return None

def nombre_archivo_valido(titulo):
    # Reemplazar caracteres no válidos para nombres de archivo
    titulo_valido = re.sub(r'[<>:"/\\|?*]', '', titulo)
    # Limitar la longitud del nombre del archivo
    return titulo_valido[:200]

def procesar_todas_las_paginas(pagina_inicio):
    paginas = obtener_todas_las_paginas(pagina_inicio)
    
    # Seleccionar 10 páginas aleatorias
    paginas_seleccionadas = random.sample(paginas, min(10, len(paginas)))

    # Asegurarse de que la carpeta de salida existe
    if not os.path.exists(carpeta_salida):
        os.makedirs(carpeta_salida)

    for i, page_id in enumerate(paginas_seleccionadas, 1):
        print(f"\nProcesando PAGINA {i}:")
        print(f"ID: {page_id}")
        html_content = obtener_contenido_html(page_id)
        if html_content:
            titulo = obtener_titulo_pagina(html_content)
            if not titulo:
                titulo = f"Pagina_{page_id}"
            
            nombre_archivo = nombre_archivo_valido(titulo)
            
            cleaned_html = clean_dokuwiki_content(html_content)
            
            # Guardar el HTML procesado en un archivo
            archivo_salida = os.path.join(carpeta_salida, f"{nombre_archivo}.html")
            with open(archivo_salida, 'w', encoding='utf-8') as f:
                f.write(cleaned_html)
            
            print(f"Título: {titulo}")
            print(f"HTML procesado guardado en: {archivo_salida}")
        else:
            print("No se pudo obtener el contenido de la página")

def process_content(content):
    content_html = ""
    for element in content.children:
        if isinstance(element, NavigableString):
            if element.strip():
                content_html += f'<p>{element.strip()}</p>\n'
        elif element.name == 'pre':
            content_html += f'<pre style="background-color: #f5f5f5; border: 1px solid #ccc; padding: 10px; border-radius: 4px; overflow-x: auto;">\n{element.text.strip()}\n</pre>\n'
        elif element.name in ['h3', 'h4']:
            content_html += f'<h3 style="font-size: 1.2em;">{element.text.strip()}</h3>\n'
        elif element.name == 'p':
            content_html += f'<p>{element.text.strip()}</p>\n'
        elif element.name == 'ul':
            content_html += process_list(element)
        elif element.name == 'div':
            content_html += process_content(element)
        else:
            content_html += str(element)
    return content_html

def process_list(ul_element):
    list_html = "<ul>\n"
    for li in ul_element.find_all('li', recursive=False):
        list_html += f"<li>{li.text.strip()}</li>\n"
    list_html += "</ul>\n"
    return list_html

# Autenticar y procesar páginas
if not autenticar():
    print("Error de autenticación")
    exit()

procesar_todas_las_paginas(pagina_cliente)

print("\nProceso completado. Los archivos HTML procesados se encuentran en:", carpeta_salida)
