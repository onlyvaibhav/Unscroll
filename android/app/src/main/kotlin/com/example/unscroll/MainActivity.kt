package com.unscroll.app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import com.unscroll.app.channels.BlockerMethodChannel

class MainActivity : FlutterActivity() {
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        BlockerMethodChannel.register(this, flutterEngine)
    }
}