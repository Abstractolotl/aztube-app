package de.aztube.aztube_app

import kotlinx.coroutines.*

abstract class AsyncTask<T> {
    private val scope = CoroutineScope(Dispatchers.Main)

    abstract suspend fun background()
    abstract suspend fun publishProgress(value: T)

    fun execute() {
        scope.launch {
            withContext(Dispatchers.Default) {
                background()
            }
        }
    }

    fun updateProgress(value: T) {
        scope.launch {
            withContext(Dispatchers.Main) {
                publishProgress(value)
            }
        }
    }
}