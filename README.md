# 📦 Recollecto

<div align="center">

**Gestiona tu colección de forma visual, organizada e inteligente**

Aplicación móvil desarrollada con **Flutter** para registrar, explorar, respaldar y buscar objetos de colección mediante fotos, con acceso web, acceso local y autenticación biométrica.

![Flutter](https://img.shields.io/badge/Flutter-Mobile-blue?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-Language-0175C2?logo=dart)
![SQLite](https://img.shields.io/badge/SQLite-Local%20Database-003B57?logo=sqlite)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-Remote%20Backup-336791?logo=postgresql)
![Status](https://img.shields.io/badge/Estado-En%20desarrollo-orange)
![Platform](https://img.shields.io/badge/Platform-Android-green)

</div>

---

## ✨ Descripción

**Recollecto** es una app pensada para coleccionistas que necesitan llevar control de sus objetos de forma rápida, visual, flexible y con opciones de respaldo.

Permite:

- registrar piezas
- agruparlas por categorías y colecciones
- almacenar varias fotos por ítem
- asignar logos a colecciones
- buscar coincidencias por imagen
- respaldar información en ZIP local
- sincronizar / restaurar SQL con PostgreSQL
- entrar en modo web o modo local

Su objetivo principal es resolver una situación muy común:

> Encuentras una figura, carta o artículo que te interesa, le tomas una foto y verificas si ya lo tienes guardado en tu colección.

---

## 🚀 Funcionalidades principales

### 📁 Gestión de colección
- Registro de ítems
- Edición de objetos guardados
- Eliminación de registros
- Vista detallada de cada pieza
- Exploración por colección y categoría

### 🏷️ Organización
- Gestión de **categorías**
- Gestión de **colecciones**
- Asociación de cada objeto a una categoría y colección
- Logo configurable para colección

### 🖼️ Fotos
- Captura desde cámara
- Selección desde galería
- Múltiples fotos por ítem
- Imagen principal por objeto
- Portada visual para colecciones

### 🔎 Búsqueda y detección
- Detección de posibles duplicados por nombre
- Detección de coincidencias por imagen
- Pantalla de análisis de imagen
- Base preparada para evolución a búsqueda visual con IA
- Comparación apoyada por hash perceptual

### 🔐 Acceso
- Crear usuario web
- Iniciar sesión web
- Entrar con huella
- Ingreso local sin clave
- Cambio de acceso desde la app

### 💾 Respaldo y sincronización
- Persistencia local con SQLite
- Respaldo local en ZIP
- Importación y restauración de ZIP
- Sincronización remota con PostgreSQL
- Restauración de datos SQL desde servidor
- Sincronización automática del contenido

---

## 📱 Caso de uso

**Ejemplo real de uso:**

1. Vas a una tienda, feria o evento
2. Encuentras una figura de tu colección
3. Tomas una foto con la app
4. Recollecto compara contra los objetos guardados
5. Verificas si ya tienes esa pieza antes de comprarla otra vez

---

## 🛠️ Stack tecnológico

| Tecnología | Uso |
|---|---|
| **Flutter** | Desarrollo de la app móvil |
| **Dart** | Lenguaje principal |
| **Sqflite / SQLite** | Base de datos local |
| **PostgreSQL** | Respaldo y restauración remota |
| **Image Picker** | Cámara y galería |
| **Path Provider** | Rutas locales de almacenamiento |
| **UUID** | Identificadores únicos |
| **image** | Procesamiento básico de imágenes |
| **MethodChannel** | Comunicación Flutter ↔ Android |
| **MediaPipe / TFLite** | Búsqueda visual con embeddings |
| **local_auth** | Huella / biometría |
| **shared_preferences** | Configuración local, sesión, tema e idioma |
| **crypto** | Hash de claves |
| **archive** | Creación y restauración de ZIP |

---

## 🧱 Arquitectura del proyecto

```text
lib/
├─ core/
│  ├─ app/
│  ├─ database/
│  ├─ localization/
│  ├─ logging/
│  ├─ utils/
│  └─ widgets/
│
├─ features/
│  ├─ auth/
│  │  ├─ data/
│  │  ├─ domain/
│  │  └─ presentation/
│  ├─ backup/
│  │  ├─ data/
│  │  ├─ domain/
│  │  └─ presentation/
│  ├─ categories/
│  ├─ collections/
│  ├─ duplicates/
│  ├─ gallery/
│  ├─ home/
│  ├─ items/
│  ├─ settings/
│  └─ splash/
│
└─ main.dart
