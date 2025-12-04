#!/bin/bash
docker build -t flutter-app .
docker run --rm -v $(pwd):/app flutter-app cp -r /app/build/app/outputs/flutter-apk/ /app/
echo "✅ APK в папке: $(pwd)/build/app/outputs/flutter-apk/"