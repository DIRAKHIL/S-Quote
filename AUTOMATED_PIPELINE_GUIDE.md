# 🚀 Automated Pipeline Guide - S-Quote macOS App

## 📋 Overview

Your S-Quote repository has a complete automated CI/CD pipeline that builds, tests, analyzes, and distributes your macOS app automatically. Here's how to use it:

## 🔄 Pipeline Triggers

### Automatic Triggers
The pipeline runs automatically when you:

1. **Push to main branch** ✅ (Currently active)
   ```bash
   git push origin main
   ```

2. **Push to develop branch** ✅
   ```bash
   git push origin develop
   ```

3. **Create Pull Request** ✅
   ```bash
   # Any PR to main branch triggers build
   ```

4. **Create Release** ✅
   ```bash
   # Creates release with DMG upload to S3
   ```

### Manual Triggers
You can also trigger the pipeline manually:

1. **Via GitHub Web Interface**:
   - Go to: https://github.com/DIRAKHIL/S-Quote/actions
   - Click on "Build macOS App" workflow
   - Click "Run workflow" button
   - Select branch and click "Run workflow"

2. **Via GitHub CLI** (if installed):
   ```bash
   gh workflow run "Build macOS App" --ref main
   ```

## 🏗️ Pipeline Components

### 1. Build Job (`build`)
**Platform**: macOS 15.5 with Xcode 16.4

**Steps**:
- ✅ Checkout code
- ✅ Setup Xcode 16.4
- ✅ Cache build artifacts
- ✅ Run tests
- ✅ Build app (Release configuration)
- ✅ Archive app (.xcarchive)
- ✅ Export app (.app)
- ✅ Create DMG installer
- ✅ Upload artifacts to GitHub
- ✅ Upload to S3 (releases only)
- ✅ Attach to GitHub releases

### 2. Analysis Job (`analyze`)
**Platform**: macOS 15.5 with Xcode 16.4

**Steps**:
- ✅ Static code analysis
- ✅ Code coverage testing
- ✅ Generate coverage reports
- ✅ Upload coverage artifacts

### 3. Quality Check Job (`quality-check`)
**Platform**: Ubuntu (faster for analysis)

**Steps**:
- ✅ Python-based code analysis
- ✅ Issue detection and reporting
- ✅ Critical issue checking
- ✅ Quality gate enforcement

## 📊 Current Pipeline Status

Check your pipeline status at:
**https://github.com/DIRAKHIL/S-Quote/actions**

### Recent Runs
- ✅ Latest push triggered build automatically
- ✅ All compilation errors have been fixed
- ✅ Pipeline should now run successfully

## 🎯 How to Run the Pipeline

### Method 1: Push Code (Recommended)
```bash
# Make any change to trigger pipeline
echo "# Pipeline trigger" >> README.md
git add README.md
git commit -m "Trigger automated pipeline"
git push origin main
```

### Method 2: Manual Trigger via GitHub
1. Visit: https://github.com/DIRAKHIL/S-Quote/actions
2. Click "Build macOS App"
3. Click "Run workflow"
4. Select "main" branch
5. Click "Run workflow"

### Method 3: Create a Release
```bash
# Create and push a tag
git tag v1.0.0
git push origin v1.0.0

# Or create release via GitHub web interface
```

## 📦 Pipeline Outputs

### Artifacts Generated
1. **DMG Installer**: `S-Quote-{commit-sha}.dmg`
2. **App Bundle**: `S-Quote.app`
3. **Coverage Report**: `coverage.json`
4. **Analysis Report**: `ANALYSIS_REPORT.md` & `ANALYSIS_REPORT.json`

### Download Locations
- **GitHub Actions Artifacts**: Available for 30 days
- **S3 Bucket**: Permanent storage (releases only)
- **GitHub Releases**: Attached to release tags

## 🔧 Pipeline Configuration

### Environment Variables
```yaml
XCODE_VERSION: '16.4'    # Matches your local setup
MACOS_VERSION: '15.5'    # Matches your local setup
```

### Required Secrets (Optional)
For S3 upload functionality:
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `AWS_S3_BUCKET`

## 🚨 Troubleshooting

### Common Issues

1. **Build Fails**
   - Check compilation errors in Actions log
   - Ensure all Swift files compile locally first
   - Verify Xcode project settings

2. **Tests Fail**
   - Currently no tests configured (will skip gracefully)
   - Add tests to `S QuoteTests` target if needed

3. **Archive Fails**
   - Check code signing settings
   - Verify bundle identifier is unique
   - Ensure all dependencies are resolved

### Debug Steps
1. Check Actions log: https://github.com/DIRAKHIL/S-Quote/actions
2. Look for red ❌ indicators
3. Click on failed job to see detailed logs
4. Fix issues locally and push again

## 🎉 Success Indicators

### ✅ Successful Pipeline Run
- All jobs show green checkmarks
- DMG file is generated
- No critical issues reported
- Artifacts are uploaded

### 📱 Ready for Distribution
- DMG installer available for download
- App bundle properly signed
- Quality checks passed
- Coverage reports generated

## 🚀 Next Steps After Successful Run

1. **Download DMG**: From GitHub Actions artifacts
2. **Test Installation**: Install and test the app
3. **Create Release**: Tag version for S3 upload
4. **Distribute**: Share DMG with users

## 📈 Monitoring

### Pipeline Health
- Monitor at: https://github.com/DIRAKHIL/S-Quote/actions
- Set up notifications for failed builds
- Review quality reports regularly

### Performance Metrics
- Build time: ~10-15 minutes
- Artifact size: ~50-100 MB
- Success rate: Target 95%+

---

## 🎯 Quick Start

**To run the pipeline right now:**

```bash
# Option 1: Trigger via push
cd "/path/to/your/S-Quote"
echo "$(date): Pipeline trigger" >> PIPELINE_LOG.md
git add PIPELINE_LOG.md
git commit -m "🚀 Trigger automated pipeline - $(date)"
git push origin main
```

**Then monitor at**: https://github.com/DIRAKHIL/S-Quote/actions

**Expected result**: 
- ✅ Build completes successfully
- ✅ DMG file generated
- ✅ Ready for distribution

---

*Your automated pipeline is ready! 🚀*
*Last updated: $(date)*