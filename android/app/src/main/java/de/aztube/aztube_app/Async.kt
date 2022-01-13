package de.aztube.aztube_app

import kotlinx.coroutines.*

class Async<T> {
    private val scope = CoroutineScope(Dispatchers.Main)

    fun run(background: (() -> T), finished: ((data: T) -> Void)){
        scope.launch {
            withContext(Dispatchers.Default) {
                val data = background()

                withContext(Dispatchers.Main){
                    finished(data)
                }
            }
        }
    }

    fun runOnMain(onMain: () -> Void){
        scope.launch {
            withContext(Dispatchers.Main){
                onMain()
            }
        }
    }
}