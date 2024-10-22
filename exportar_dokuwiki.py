from bs4 import BeautifulSoup, NavigableString
import re
import os
import requests

# Configuración
url_base = 'https://doku.plexus.es'
username = 'victor.jimenezvaquer'
password = 'XV(s98v%ofMj)7'
pagina_cliente = '236_telefonica_producto'
codigo_cliente = '236'
carpeta_salida = r"C:\Users\victor.jimenezvaquer\Desktop\PROYECTOS_PLEXUS\PROYECTO_WIKI\JSONS\236 - Telefonica"  # Añade esta línea

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
    
    for section in main_content.find_all('div', class_=re.compile('(sectionedit|bs-wrap bs-callout)')):
        cleaned_html += process_section(section)
    
    # Procesar imágenes
    for img in main_content.find_all('img'):
        img_src = img.get('src')
        if img_src:
            cleaned_html += f'<img src="{img_src}" alt="{img.get("alt", "")}" style="max-width: 100%; height: auto; margin: 10px 0;">\n'
    
    cleaned_html += "</body>"
    return cleaned_html

def process_section(section):
    section_html = f'<section style="margin: 20px 0; padding: 15px; border: 1px solid #e3e3e3; border-radius: 4px;">\n'
    
    # Procesamos directamente el contenido de la sección sin incluir el título
    section_html += f'<div style="margin-top: 10px;">\n'
    section_html += process_content(section)
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
    
    if not os.path.exists(carpeta_salida):
        os.makedirs(carpeta_salida)

    for page_id in paginas:
        print(f"\nProcesando página: {page_id}")
        html_content = obtener_contenido_html(page_id)
        if html_content:
            titulo = obtener_titulo_pagina(html_content)
            if not titulo:
                titulo = f"Pagina_{page_id}"
            
            nombre_archivo = nombre_archivo_valido(titulo)
            
            solo_enlaces, contenido_html = analizar_contenido_pagina(html_content)
            es_proyecto = es_pagina_proyecto(titulo)
            
            print(f"Es página de proyecto: {'Sí' if es_proyecto else 'No'}")
            print(f"Contiene solo enlaces: {'Sí' if solo_enlaces else 'No'}")
            
            if es_proyecto and solo_enlaces:
                # Crear una carpeta para el proyecto
                carpeta_proyecto = os.path.join(carpeta_salida, nombre_archivo)
                os.makedirs(carpeta_proyecto, exist_ok=True)
                print(f"Carpeta de proyecto creada en: {carpeta_proyecto}")
            else:
                # Procesar como una página normal
                cleaned_html = clean_dokuwiki_content(contenido_html)
                archivo_salida = os.path.join(carpeta_salida, f"{nombre_archivo}.html")
                with open(archivo_salida, 'w', encoding='utf-8') as f:
                    f.write(cleaned_html)
                print(f"HTML procesado guardado en: {archivo_salida}")
        else:
            print("No se pudo obtener el contenido de la página")

def es_pagina_proyecto(titulo):
    # Verificar si el título comienza con el código de cliente seguido de un guión y tres dígitos
    patron_proyecto = re.compile(f'^{codigo_cliente}-\\d{{3}}')
    return bool(patron_proyecto.match(titulo))

def process_content(content):
    content_html = ""
    current_paragraph = ""
    
    for element in content.children:
        if isinstance(element, NavigableString):
            current_paragraph += str(element)
        elif element.name == 'pre':
            if current_paragraph:
                content_html += f'<p>{current_paragraph.strip()}</p>\n'
                current_paragraph = ""
            content_html += f'<pre style="background-color: #f5f5f5; border: 1px solid #ccc; padding: 10px; border-radius: 4px; overflow-x: auto;">\n{element.text.strip()}\n</pre>\n'
        elif element.name in ['h3', 'h4']:
            if current_paragraph:
                content_html += f'<p>{current_paragraph.strip()}</p>\n'
                current_paragraph = ""
            content_html += f'<h3 style="font-size: 1.2em;">{element.text.strip()}</h3>\n'
        elif element.name == 'p':
            if current_paragraph:
                content_html += f'<p>{current_paragraph.strip()}</p>\n'
                current_paragraph = ""
            content_html += f'<p>{element.decode_contents()}</p>\n'
        elif element.name == 'ul':
            if current_paragraph:
                content_html += f'<p>{current_paragraph.strip()}</p>\n'
                current_paragraph = ""
            content_html += process_list(element)
        elif element.name == 'div':
            if current_paragraph:
                content_html += f'<p>{current_paragraph.strip()}</p>\n'
                current_paragraph = ""
            content_html += process_content(element)
        elif element.name in ['span', 'strong', 'em', 'a']:
            current_paragraph += str(element)
        else:
            current_paragraph += str(element)
    
    if current_paragraph:
        content_html += f'<p>{current_paragraph.strip()}</p>\n'
    
    return content_html

def process_list(ul_element):
    list_html = "<ul>\n"
    for li in ul_element.find_all('li', recursive=False):
        list_html += f"<li>{li.text.strip()}</li>\n"
    list_html += "</ul>\n"
    return list_html

def analizar_contenido_pagina(html_content):
    soup = BeautifulSoup(html_content, 'html.parser')
    main_content = soup.find('div', class_='dokuwiki export')
    
    if not main_content:
        print("No se encontró el contenido principal")
        return False, ""
    
    # Buscar el título h1
    h1 = main_content.find('h1')
    
    # Buscar la lista ul (ahora buscamos cualquier ul, no solo con class='level1')
    ul = main_content.find('ul')
    
    # Contar enlaces dentro de todo el contenido principal
    links = main_content.find_all('a', class_='wikilink1')
    
    # Imprimir información sobre la estructura de la página
    print(f"Título h1: {'Sí' if h1 else 'No'}")
    print(f"Lista ul: {'Sí' if ul else 'No'}")
    print(f"Número de enlaces: {len(links)}")
    
    # Determinar si la página contiene solo enlaces
    solo_enlaces = h1 and ul and len(links) > 0 and len(main_content.find_all(['p', 'pre', 'h2', 'h3', 'h4'])) == 0
    
    # Imprimir si la página contiene solo enlaces
    print(f"Contiene solo enlaces: {'Sí' if solo_enlaces else 'No'}")
    
    return solo_enlaces, str(main_content)

# Autenticar y procesar páginas
if not autenticar():
    print("Error de autenticación")
    exit()

procesar_todas_las_paginas(pagina_cliente)

print("\nProceso completado")
