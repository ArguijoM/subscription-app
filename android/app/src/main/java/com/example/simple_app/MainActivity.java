package com.example.simple_app;

import android.os.Bundle;
import io.flutter.embedding.android.FlutterFragmentActivity;

public class MainActivity extends FlutterFragmentActivity {
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        // Forzar el theme correcto antes de inicializar Flutter
        setTheme(R.style.NormalTheme);
        super.onCreate(savedInstanceState);
    }
}
