# วิธีสร้างไฟล์เกมสำหรับ Android (APK / AAB)

> โปรเจกต์มี `export_presets.cfg` ตั้งค่า Android และ Windows ไว้แล้ว ทำตามขั้นตอนนี้บนเครื่องของคุณ (ครั้งแรกใช้เวลาประมาณ 30-60 นาที)

## 1. ติดตั้งของที่ต้องใช้ (ครั้งเดียว)
1. **Godot 4.3+** (Standard) และ **Export Templates** ของเวอร์ชันเดียวกัน
   ใน Godot: เมนู **Editor → Manage Export Templates → Download and Install**
2. **Java JDK 17** (เช่น Eclipse Temurin 17)
3. **Android SDK**: ติดตั้ง **Android Studio** แล้วเปิด SDK Manager ติดตั้ง
   *Android SDK Platform-Tools*, *Build-Tools 34*, *Platform 34*, *Command-line Tools*
4. ใน Godot: **Editor → Editor Settings → Export → Android** ใส่ path ของ
   *Java SDK Path* และ *Android SDK Path*

## 2. สร้างกุญแจเซ็นแอป (ครั้งเดียว แล้ว **เก็บไฟล์ให้ดี ห้ามหาย**)
```bash
keytool -genkey -v -keystore curseddice-release.keystore -alias curseddice -keyalg RSA -keysize 2048 -validity 10000
```
ใน Godot: **Project → Export → Android → Keystore → Release** ใส่ไฟล์, alias และรหัสผ่าน

> ⚠️ อย่า commit ไฟล์ keystore หรือรหัสผ่านขึ้น GitHub เด็ดขาด ถ้าหาย จะอัปเดตแอปบน Play Store ไม่ได้อีก

## 3. ตั้งชื่อแพ็กเกจ
ใน preset Android เปลี่ยน **Package → Unique Name** จาก `com.example.curseddice` เป็นชื่อของคุณเอง
เช่น `com.<ชื่อคุณ>.curseddice` (เปลี่ยนภายหลังไม่ได้เมื่อขึ้น Play Store แล้ว)

## 4. Export
- ทดสอบบนมือถือ: เสียบสาย USB, เปิด *USB debugging* แล้วกดไอคอน Android ▶ มุมขวาบนของ Godot
- สร้างไฟล์: **Project → Export → Android → Export Project** → ได้ `export/CursedDice.apk`
- สำหรับ Play Store ต้องใช้ **AAB**: ติ๊ก *Use Gradle Build* → ติดตั้ง Android Build Template → Export เป็น `.aab`

## 5. ก่อนขึ้น Play Store
- ทดสอบบนมือถือจริงอย่างน้อย 1 เครื่อง (ควรเป็นรุ่นสเปกต่ำ)
- เตรียม: ไอคอน 512×512, ภาพหน้าจอ, คำอธิบาย, นโยบายความเป็นส่วนตัว (เกมไม่เก็บข้อมูลผู้ใช้ ไม่ต่อเน็ต)
- แบบฟอร์ม Play Console: ระบุว่าเกมมีกาชาที่ **ไม่ใช้เงินจริง** และมีเนื้อหาจาก AI (ถ้าใช้ภาพ/เสียง AI)
- เริ่มที่ **Internal testing → Closed testing → Production**
