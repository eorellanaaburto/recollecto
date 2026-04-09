# 📦 Recollecto

<div align="center">

**Gestiona tu colección de forma visual, organizada e inteligente**

Aplicación móvil desarrollada con **Flutter** para registrar, explorar y buscar objetos de colección mediante fotos.

![Flutter](https://img.shields.io/badge/Flutter-Mobile-blue?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-Language-0175C2?logo=dart)
![SQLite](https://img.shields.io/badge/SQLite-Local%20Database-003B57?logo=sqlite)
![Status](https://img.shields.io/badge/Estado-En%20desarrollo-orange)
![Platform](https://img.shields.io/badge/Platform-Android-green)

</div>

---

## ✨ Descripción

**Recollecto** es una app pensada para coleccionistas que necesitan llevar control de sus objetos de forma rápida y visual.

Permite registrar piezas, agruparlas por categorías y colecciones, almacenar varias fotos por ítem y revisar si un objeto ya existe dentro de la colección.

Su objetivo principal es resolver una situación muy común:

> Encuentras una figura, carta o artículo que te interesa, le tomas una foto y verificas si ya lo tienes guardado en tu colección.

---

## 🚀 Funcionalidades principales

### 📁 Gestión de colección
- Registro de ítems
- Edición de objetos guardados
- Eliminación de registros
- Vista detallada de cada pieza

### 🏷️ Organización
- Gestión de **categorías**
- Gestión de **colecciones**
- Asociación de cada objeto a una categoría y colección

### 🖼️ Fotos
- Captura desde cámara
- Selección desde galería
- Múltiples fotos por ítem
- Imagen principal por objeto

### 🔎 Búsqueda y detección
- Detección de posibles duplicados por nombre
- Detección de coincidencias por imagen
- Pantalla de análisis de imagen
- Base preparada para evolución a búsqueda visual con IA

### 💾 Datos
- Persistencia local
- Respaldo / sincronización
- Estructura lista para crecimiento del proyecto

---

## 📱 Caso de uso

**Ejemplo real de uso:**

1. Vas a una tienda, feria o evento
2. Encuentras una figura de tu colección
3. Tomas una foto con la app
4. Recollecto compara contra los objetos guardados
5. Revisa si ya tienes esa pieza antes de comprarla otra vez

---

## 🛠️ Stack tecnológico

| Tecnología | Uso |
|---|---|
| **Flutter** | Desarrollo de la app móvil |
| **Dart** | Lenguaje principal |
| **Sqflite / SQLite** | Base de datos local |
| **Image Picker** | Cámara y galería |
| **Path Provider** | Rutas locales de almacenamiento |
| **UUID** | Identificadores únicos |
| **image** | Procesamiento básico de imágenes |
| **MethodChannel** | Comunicación Flutter ↔ Android |
| **MediaPipe / TFLite** | Búsqueda visual con embeddings |

---

## 🧱 Arquitectura del proyecto

```text
lib/
├─ core/
│  ├─ database/
│  ├─ localization/
│  └─ widgets/
│
├─ features/
│  ├─ ai/
│  │  └─ data/
│  ├─ backup/
│  ├─ categories/
│  ├─ collections/
│  ├─ duplicates/
│  ├─ gallery/
│  ├─ home/
│  ├─ items/
│  └─ settings/
│
└─ main.dart
