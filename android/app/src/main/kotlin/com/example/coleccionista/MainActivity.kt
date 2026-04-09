package com.example.coleccionista

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "com.example.coleccionista/image_embedder"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val bridge = ImageEmbedderBridge(applicationContext)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            channelName
        ).setMethodCallHandler { call, result ->

            when (call.method) {
                "generateEmbedding" -> {
                    try {
                        val imagePath = call.argument<String>("imagePath")
                            ?: throw IllegalArgumentException("Falta imagePath")

                        val embedding = bridge.generateEmbedding(imagePath)
                        result.success(embedding)
                    } catch (e: Exception) {
                        result.error(
                            "EMBEDDING_ERROR",
                            e.message,
                            null
                        )
                    }
                }

                "findMatches" -> {
                    try {
                        val queryImagePath = call.argument<String>("queryImagePath")
                            ?: throw IllegalArgumentException("Falta queryImagePath")

                        val rawCandidates =
                            call.argument<List<Map<String, Any?>>>("candidates")
                                ?: emptyList()

                        val minScore =
                            call.argument<Double>("minScore") ?: 0.80

                        val limit =
                            call.argument<Int>("limit") ?: 5

                        val matches = bridge.findMatches(
                            queryImagePath = queryImagePath,
                            candidates = rawCandidates,
                            minScore = minScore,
                            limit = limit
                        )

                        result.success(matches)
                    } catch (e: Exception) {
                        result.error(
                            "MATCH_ERROR",
                            e.message,
                            null
                        )
                    }
                }

                else -> result.notImplemented()
            }
        }
    }
}