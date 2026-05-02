# Production Deployment Guide

This guide outlines the steps to deploy the **K-Beauty House Inventory System** to a production server using its GitHub repository.

## 1. Backend Deployment (Laravel)

We recommend a Linux VPS (Ubuntu 22.04+) with Nginx, PHP 8.2+, and MySQL 8.

### Prerequisites
- Install PHP, Nginx, MySQL, and Composer on your server.
- Ensure your domain's A record points to your server's IP.

### Step 1: Clone the Repository
```bash
cd /var/www
git clone https://github.com/aswinadi/kbeauty.git
cd kbeauty/backend
```

### Step 2: Configure Environment
```bash
cp .env.example .env
nano .env
```
Update the following:
- `APP_ENV=production`
- `APP_URL=https://your-domain.com`
- `DB_DATABASE`, `DB_USERNAME`, `DB_PASSWORD`
- `FILESYSTEM_DISK=public`

### Step 3: Install Dependencies
```bash
composer install --no-dev --optimize-autoloader
npm install && npm run build
```

### Step 4: Finalize Setup
```bash
php artisan key:generate
php artisan storage:link
php artisan migrate --force
php artisan filament:optimize
```

### Step 5: Nginx Configuration
Ensure your Nginx site configuration points to `/var/www/kbeauty/backend/public`.

---

## 2. Mobile App Deployment (Flutter)

### Step 1: Update API Base URL
In `mobile/lib/services/inventory_service.dart`, update the `baseUrl`:
```dart
static const String baseUrl = 'https://your-domain.com/api';
```

### Step 2: Configure Signing (Optional but Recommended)
To sign your app for the Play Store:
1. **Generate a Keystore**:
   ```bash
   keytool -genkey -v -keystore mobile/android/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias key
   ```
2. **Create `key.properties`**:
   Create `mobile/android/key.properties` based on `key.properties.example`:
   ```properties
   storePassword=your_password_from_step_1
   keyPassword=your_password_from_step_1
   keyAlias=key
   storeFile=../upload-keystore.jks
   ```

### Step 3: Build for Android (APK)

**Option A: Command Line (Recommended)**
```bash
cd mobile
flutter clean
flutter pub get
flutter build apk --release \
  --dart-define=ENV=prod \
  --dart-define=API_URL=https://inventory.maxmar.net/api \
  --build-name=1.0.0 \
  --build-number=1
```

**Option B: Android Studio**
1. Open the project in Android Studio.
2. Go to **Run > Edit Configurations**.
3. Click **+** and select **Flutter**.
4. Name it "Production Build".
5. In **Additional run args**, add:
   `--release --dart-define=ENV=prod --dart-define=API_URL=https://inventory.maxmar.net/api`
6. Click **OK** and then **Run** (Play button) to build and install on a connected device.
   *Note: To just generate the APK without running, use Option A.*

**Option C: Build Button (Android Studio)**
To created a dedicated "Build" button in your toolbar:
1. Go to **Run > Edit Configurations**.
2. Click **+** and select **Shell Script**.
3. Name it "Build Prod APK".
4. In **Script text**, paste:
   ```bash
   flutter build apk --release --dart-define=ENV=prod --dart-define=API_URL=https://inventory.maxmar.net/api --build-name=1.0.0 --build-number=1
   ```
5. In **Working Directory**, select the `mobile` folder.
6. Click **OK**.
7. Now select "Build Prod APK" and click **Run**. This will build the file without launching the app.

The APK will be signed with your release key if configured, otherwise it uses the debug key.

### Step 4: Build for iOS (IPA)

**Prerequisites:**
- You must be using a macOS computer.
- Xcode installed.
- Apple Developer Account.

**Step 4.1: Configure Signing**
1. Open the iOS project in Xcode:
   ```bash
   open mobile/ios/Runner.xcworkspace
   ```
2. Convert the `API_URL` environment variable. Since iOS builds don't easily read `dart-define` during archive, it's best to hardcode the production URL in `mobile/lib/config/app_config.dart` or ensure `Product.xcconfig` is set up (advanced).
   *For simplicity, ensure `AppConfig.dart` defaults to production URL if `kReleaseMode` is true.*

3. In Xcode, go to **Runner** (target) > **Signing & Capabilities**.
4. Select your **Team** and ensure "Automatically manage signing" is checked.

**Step 4.2: Build Archive**
Run the build command in your terminal:
```bash
cd mobile
flutter build ipa --release \
  --dart-define=ENV=prod \
  --dart-define=API_URL=https://inventory.maxmar.net/api \
  --export-options-plist=ios/ExportOptions.plist
```
*Note: You may need to create an `ExportOptions.plist` file or simply use Xcode's **Product > Archive** menu option which is often easier for iOS.*

**Option B: Xcode Archive (Recommended)**
1. Open `mobile/ios/Runner.xcworkspace`.
2. Select **Product > Archive**.
3. Once finished, the Organizer window will open.
4. Click **Distribute App** to upload to TestFlight or App Store.

### Step 5: Development Build
To run in development mode with your local server:
```bash
flutter run --dart-define=ENV=dev --dart-define=API_URL=http://localhost:8000/api
```

### Step 6: App Versioning
To bump the app version, you can either:
1. Update `version: 1.0.0+1` in `pubspec.yaml`
2. Or override it during build: `--build-name=1.0.1 --build-number=2`

---

## 3. Post-Deployment Maintenance
- **Cron Job**: Add the Laravel scheduler to your server:
  `* * * * * cd /path-to-your-project && php artisan schedule:run >> /dev/null 2>&1`
- **Backups**: Set up automated database backups.
- **SSL**: Always use HTTPS (e.g., via Certbot/Let's Encrypt).
