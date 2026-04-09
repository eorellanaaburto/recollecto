package com.example.coleccionista

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Matrix
import androidx.exifinterface.media.ExifInterface
import com.google.mediapipe.framework.image.BitmapImageBuilder
import com.google.mediapipe.tasks.core.BaseOptions
import com.google.mediapipe.tasks.vision.core.RunningMode
import com.google.mediapipe.tasks.vision.imageembedder.ImageEmbedder
import com.google.mediapipe.tasks.vision.imageembedder.ImageEmbedderResult
import java.io.File
import kotlin.math.sqrt

class ImageEmbedderBridge(private val context: Context) {

    private val modelName = "image_embedder.tflite"

    private val imageEmbedder: ImageEmbedder by lazy {
        val baseOptions = BaseOptions.builder()
            .setModelAssetPath(modelName)
            .build()

        val options = ImageEmbedder.ImageEmbedderOptions.builder()
            .setBaseOptions(baseOptions)
            .setRunningMode(RunningMode.IMAGE)
            .setL2Normalize(true)
            .setQuantize(false)
            .build()

        ImageEmbedder.createFromOptions(context, options)
    }

    fun generateEmbedding(imagePath: String): List<Double> {
        val bitmap = loadBitmapRespectingExif(imagePath)
        val mpImage = BitmapImageBuilder(bitmap).build()
        val result: ImageEmbedderResult = imageEmbedder.embed(mpImage)

        val embeddingResult = result.embeddingResult()
            ?: throw IllegalStateException("El modelo no devolvió embeddingResult")

        val embeddings = embeddingResult.embeddings()
        if (embeddings.isEmpty()) {
            throw IllegalStateException("El modelo no devolvió embeddings")
        }

        val firstEmbedding = embeddings[0]

        val floatEmbedding = firstEmbedding.floatEmbedding()
        if (floatEmbedding != null) {
            return floatEmbedding.toList().map { it.toDouble() }
        }

        val quantizedEmbedding = firstEmbedding.quantizedEmbedding()
        if (quantizedEmbedding != null) {
            return quantizedEmbedding.toList().map { it.toDouble() }
        }

        throw IllegalStateException("No se pudo leer el embedding")
    }

    fun findMatches(
        queryImagePath: String,
        candidates: List<Map<String, Any?>>,
        minScore: Double,
        limit: Int
    ): List<Map<String, Any>> {
        val queryEmbedding = generateEmbedding(queryImagePath)

        val matches = mutableListOf<Map<String, Any>>()

        for (candidate in candidates) {
            val itemId = candidate["itemId"] as? String ?: continue
            val title = candidate["title"] as? String ?: ""
            val categoryName = candidate["categoryName"] as? String ?: ""
            val collectionName = candidate["collectionName"] as? String ?: ""
            val photoPath = candidate["photoPath"] as? String ?: continue

            val candidateEmbedding = try {
                generateEmbedding(photoPath)
            } catch (_: Exception) {
                continue
            }

            if (queryEmbedding.size != candidateEmbedding.size) continue

            val score = cosineSimilarity(queryEmbedding, candidateEmbedding)

            if (score >= minScore) {
                matches.add(
                    mapOf(
                        "itemId" to itemId,
                        "title" to title,
                        "categoryName" to categoryName,
                        "collectionName" to collectionName,
                        "photoPath" to photoPath,
                        "score" to score
                    )
                )
            }
        }

        return matches
            .sortedByDescending { (it["score"] as Double) }
            .take(limit)
    }

    private fun cosineSimilarity(a: List<Double>, b: List<Double>): Double {
        var dot = 0.0
        var normA = 0.0
        var normB = 0.0

        for (i in a.indices) {
            dot += a[i] * b[i]
            normA += a[i] * a[i]
            normB += b[i] * b[i]
        }

        if (normA == 0.0 || normB == 0.0) return 0.0

        return dot / (sqrt(normA) * sqrt(normB))
    }

    private fun loadBitmapRespectingExif(path: String): Bitmap {
        val file = File(path)
        require(file.exists()) { "No existe la imagen: $path" }

        val bitmap = BitmapFactory.decodeFile(path)
            ?: throw IllegalStateException("No se pudo decodificar la imagen: $path")

        val exif = ExifInterface(path)
        val orientation = exif.getAttributeInt(
            ExifInterface.TAG_ORIENTATION,
            ExifInterface.ORIENTATION_NORMAL
        )

        val matrix = Matrix()

        when (orientation) {
            ExifInterface.ORIENTATION_ROTATE_90 -> matrix.postRotate(90f)
            ExifInterface.ORIENTATION_ROTATE_180 -> matrix.postRotate(180f)
            ExifInterface.ORIENTATION_ROTATE_270 -> matrix.postRotate(270f)
            ExifInterface.ORIENTATION_FLIP_HORIZONTAL -> matrix.preScale(-1f, 1f)
            ExifInterface.ORIENTATION_FLIP_VERTICAL -> matrix.preScale(1f, -1f)
        }

        return if (matrix.isIdentity) {
            bitmap
        } else {
            Bitmap.createBitmap(
                bitmap,
                0,
                0,
                bitmap.width,
                bitmap.height,
                matrix,
                true
            )
        }
    }
}