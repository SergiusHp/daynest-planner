# Генерує MyauDen.xcodeproj (формат Xcode 16: папки синхронізуються автоматично — нові файли не треба додавати вручну).
import hashlib, os, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
APP, TESTS = "MyauDen", "MyauDenUITests"
BUNDLE_ID = "com.sergiushp.myauden"

def oid(name):
    return hashlib.md5(name.encode()).hexdigest()[:24].upper()

I = {k: oid(k) for k in [
    "project", "maingroup", "products", "appgroup", "testgroup", "appproduct", "testproduct",
    "apptarget", "testtarget", "appsources", "appframeworks", "appresources", "testsources",
    "testframeworks", "testresources", "proxy", "dependency", "exceptions",
    "projcfglist", "projdebug", "projrelease", "appcfglist", "appdebug", "apprelease",
    "testcfglist", "testdebug", "testrelease"]}

def settings(d, indent="\t\t\t\t"):
    out = []
    for k, v in d.items():
        if isinstance(v, list):
            out.append(f"{indent}{k} = (")
            out += [f'{indent}\t"{x}",' for x in v]
            out.append(f"{indent});")
        else:
            needs = any(c in str(v) for c in ' $()"-/,.+') or str(v) == ""
            val = '"' + str(v).replace('"', '\\"') + '"' if needs else str(v)
            out.append(f"{indent}{k} = {val};")
    return "\n".join(out)

common = {
    "ALWAYS_SEARCH_USER_PATHS": "NO",
    "ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS": "YES",
    "CLANG_ANALYZER_NONNULL": "YES",
    "CLANG_CXX_LANGUAGE_STANDARD": "gnu++20",
    "CLANG_ENABLE_MODULES": "YES",
    "CLANG_ENABLE_OBJC_ARC": "YES",
    "CLANG_ENABLE_OBJC_WEAK": "YES",
    "COPY_PHASE_STRIP": "NO",
    "ENABLE_STRICT_OBJC_MSGSEND": "YES",
    "ENABLE_USER_SCRIPT_SANDBOXING": "YES",
    "GCC_C_LANGUAGE_STANDARD": "gnu17",
    "GCC_NO_COMMON_BLOCKS": "YES",
    "IPHONEOS_DEPLOYMENT_TARGET": "17.0",
    "LOCALIZATION_PREFERS_STRING_CATALOGS": "YES",
    "MTL_FAST_MATH": "YES",
    "SDKROOT": "iphoneos",
}
proj_debug = {**common, "DEBUG_INFORMATION_FORMAT": "dwarf", "ENABLE_TESTABILITY": "YES", "GCC_DYNAMIC_NO_PIC": "NO",
              "GCC_OPTIMIZATION_LEVEL": "0", "GCC_PREPROCESSOR_DEFINITIONS": ["DEBUG=1", "$(inherited)"],
              "MTL_ENABLE_DEBUG_INFO": "INCLUDE_SOURCE", "ONLY_ACTIVE_ARCH": "YES",
              "SWIFT_ACTIVE_COMPILATION_CONDITIONS": "DEBUG $(inherited)", "SWIFT_OPTIMIZATION_LEVEL": "-Onone"}
proj_release = {**common, "DEBUG_INFORMATION_FORMAT": "dwarf-with-dsym", "ENABLE_NS_ASSERTIONS": "NO",
                "MTL_ENABLE_DEBUG_INFO": "NO", "SWIFT_COMPILATION_MODE": "wholemodule", "VALIDATE_PRODUCT": "YES"}
app = {
    "ASSETCATALOG_COMPILER_APPICON_NAME": "AppIcon",
    "ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME": "AccentColor",
    "CODE_SIGN_STYLE": "Automatic",
    "CURRENT_PROJECT_VERSION": "1",
    "DEVELOPMENT_TEAM": "",
    "ENABLE_PREVIEWS": "YES",
    "GENERATE_INFOPLIST_FILE": "YES",
    "INFOPLIST_FILE": f"{APP}/Info.plist",
    "INFOPLIST_KEY_CFBundleDisplayName": "Мій МЯУдень",
    "INFOPLIST_KEY_LSApplicationCategoryType": "public.app-category.productivity",
    "INFOPLIST_KEY_UIApplicationSceneManifest_Generation": "YES",
    "INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents": "YES",
    "INFOPLIST_KEY_UIRequiresFullScreen": "YES",
    "INFOPLIST_KEY_UISupportedInterfaceOrientations": "UIInterfaceOrientationPortrait",
    "LD_RUNPATH_SEARCH_PATHS": ["$(inherited)", "@executable_path/Frameworks"],
    "MARKETING_VERSION": "1.0",
    "PRODUCT_BUNDLE_IDENTIFIER": BUNDLE_ID,
    "PRODUCT_NAME": "$(TARGET_NAME)",
    "SWIFT_EMIT_LOC_STRINGS": "YES",
    "SWIFT_VERSION": "5.0",
    "TARGETED_DEVICE_FAMILY": "1",
}
test = {
    "CODE_SIGN_STYLE": "Automatic",
    "CURRENT_PROJECT_VERSION": "1",
    "DEVELOPMENT_TEAM": "",
    "GENERATE_INFOPLIST_FILE": "YES",
    "MARKETING_VERSION": "1.0",
    "PRODUCT_BUNDLE_IDENTIFIER": BUNDLE_ID + ".uitests",
    "PRODUCT_NAME": "$(TARGET_NAME)",
    "SWIFT_EMIT_LOC_STRINGS": "NO",
    "SWIFT_VERSION": "5.0",
    "TARGETED_DEVICE_FAMILY": "1",
    "TEST_TARGET_NAME": APP,
}

def cfg(id_, name, s):
    return f"""\t\t{id_} /* {name} */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
{settings(s)}
\t\t\t}};
\t\t\tname = {name};
\t\t}};"""

def phase(id_, isa, name):
    return f"""\t\t{id_} /* {name} */ = {{
\t\t\tisa = {isa};
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};"""

def cfglist(id_, comment, d, r):
    return f"""\t\t{id_} /* Build configuration list for {comment} */ = {{
\t\t\tisa = XCConfigurationList;
\t\t\tbuildConfigurations = (
\t\t\t\t{d} /* Debug */,
\t\t\t\t{r} /* Release */,
\t\t\t);
\t\t\tdefaultConfigurationIsVisible = 0;
\t\t\tdefaultConfigurationName = Release;
\t\t}};"""

pbx = f"""// !$*UTF8*$!
{{
\tarchiveVersion = 1;
\tclasses = {{
\t}};
\tobjectVersion = 77;
\tobjects = {{

/* Begin PBXContainerItemProxy section */
\t\t{I['proxy']} /* PBXContainerItemProxy */ = {{
\t\t\tisa = PBXContainerItemProxy;
\t\t\tcontainerPortal = {I['project']} /* Project object */;
\t\t\tproxyType = 1;
\t\t\tremoteGlobalIDString = {I['apptarget']};
\t\t\tremoteInfo = {APP};
\t\t}};
/* End PBXContainerItemProxy section */

/* Begin PBXFileReference section */
\t\t{I['appproduct']} /* {APP}.app */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = {APP}.app; sourceTree = BUILT_PRODUCTS_DIR; }};
\t\t{I['testproduct']} /* {TESTS}.xctest */ = {{isa = PBXFileReference; explicitFileType = wrapper.cfbundle; includeInIndex = 0; path = {TESTS}.xctest; sourceTree = BUILT_PRODUCTS_DIR; }};
/* End PBXFileReference section */

/* Begin PBXFileSystemSynchronizedBuildFileExceptionSet section */
\t\t{I['exceptions']} /* Exceptions for "{APP}" folder in "{APP}" target */ = {{
\t\t\tisa = PBXFileSystemSynchronizedBuildFileExceptionSet;
\t\t\tmembershipExceptions = (
\t\t\t\tInfo.plist,
\t\t\t);
\t\t\ttarget = {I['apptarget']} /* {APP} */;
\t\t}};
/* End PBXFileSystemSynchronizedBuildFileExceptionSet section */

/* Begin PBXFileSystemSynchronizedRootGroup section */
\t\t{I['appgroup']} /* {APP} */ = {{
\t\t\tisa = PBXFileSystemSynchronizedRootGroup;
\t\t\texceptions = (
\t\t\t\t{I['exceptions']} /* Exceptions for "{APP}" folder in "{APP}" target */,
\t\t\t);
\t\t\tpath = {APP};
\t\t\tsourceTree = "<group>";
\t\t}};
\t\t{I['testgroup']} /* {TESTS} */ = {{
\t\t\tisa = PBXFileSystemSynchronizedRootGroup;
\t\t\tpath = {TESTS};
\t\t\tsourceTree = "<group>";
\t\t}};
/* End PBXFileSystemSynchronizedRootGroup section */

/* Begin PBXFrameworksBuildPhase section */
{phase(I['appframeworks'], 'PBXFrameworksBuildPhase', 'Frameworks')}
{phase(I['testframeworks'], 'PBXFrameworksBuildPhase', 'Frameworks')}
/* End PBXFrameworksBuildPhase section */

/* Begin PBXGroup section */
\t\t{I['maingroup']} = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
\t\t\t\t{I['appgroup']} /* {APP} */,
\t\t\t\t{I['testgroup']} /* {TESTS} */,
\t\t\t\t{I['products']} /* Products */,
\t\t\t);
\t\t\tsourceTree = "<group>";
\t\t}};
\t\t{I['products']} /* Products */ = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
\t\t\t\t{I['appproduct']} /* {APP}.app */,
\t\t\t\t{I['testproduct']} /* {TESTS}.xctest */,
\t\t\t);
\t\t\tname = Products;
\t\t\tsourceTree = "<group>";
\t\t}};
/* End PBXGroup section */

/* Begin PBXNativeTarget section */
\t\t{I['apptarget']} /* {APP} */ = {{
\t\t\tisa = PBXNativeTarget;
\t\t\tbuildConfigurationList = {I['appcfglist']} /* Build configuration list for PBXNativeTarget "{APP}" */;
\t\t\tbuildPhases = (
\t\t\t\t{I['appsources']} /* Sources */,
\t\t\t\t{I['appframeworks']} /* Frameworks */,
\t\t\t\t{I['appresources']} /* Resources */,
\t\t\t);
\t\t\tbuildRules = (
\t\t\t);
\t\t\tdependencies = (
\t\t\t);
\t\t\tfileSystemSynchronizedGroups = (
\t\t\t\t{I['appgroup']} /* {APP} */,
\t\t\t);
\t\t\tname = {APP};
\t\t\tpackageProductDependencies = (
\t\t\t);
\t\t\tproductName = {APP};
\t\t\tproductReference = {I['appproduct']} /* {APP}.app */;
\t\t\tproductType = "com.apple.product-type.application";
\t\t}};
\t\t{I['testtarget']} /* {TESTS} */ = {{
\t\t\tisa = PBXNativeTarget;
\t\t\tbuildConfigurationList = {I['testcfglist']} /* Build configuration list for PBXNativeTarget "{TESTS}" */;
\t\t\tbuildPhases = (
\t\t\t\t{I['testsources']} /* Sources */,
\t\t\t\t{I['testframeworks']} /* Frameworks */,
\t\t\t\t{I['testresources']} /* Resources */,
\t\t\t);
\t\t\tbuildRules = (
\t\t\t);
\t\t\tdependencies = (
\t\t\t\t{I['dependency']} /* PBXTargetDependency */,
\t\t\t);
\t\t\tfileSystemSynchronizedGroups = (
\t\t\t\t{I['testgroup']} /* {TESTS} */,
\t\t\t);
\t\t\tname = {TESTS};
\t\t\tpackageProductDependencies = (
\t\t\t);
\t\t\tproductName = {TESTS};
\t\t\tproductReference = {I['testproduct']} /* {TESTS}.xctest */;
\t\t\tproductType = "com.apple.product-type.bundle.ui-testing";
\t\t}};
/* End PBXNativeTarget section */

/* Begin PBXProject section */
\t\t{I['project']} /* Project object */ = {{
\t\t\tisa = PBXProject;
\t\t\tattributes = {{
\t\t\t\tBuildIndependentTargetsInParallel = 1;
\t\t\t\tLastSwiftUpdateCheck = 1640;
\t\t\t\tLastUpgradeCheck = 1640;
\t\t\t\tTargetAttributes = {{
\t\t\t\t\t{I['apptarget']} = {{
\t\t\t\t\t\tCreatedOnToolsVersion = 16.4;
\t\t\t\t\t}};
\t\t\t\t\t{I['testtarget']} = {{
\t\t\t\t\t\tCreatedOnToolsVersion = 16.4;
\t\t\t\t\t\tTestTargetID = {I['apptarget']};
\t\t\t\t\t}};
\t\t\t\t}};
\t\t\t}};
\t\t\tbuildConfigurationList = {I['projcfglist']} /* Build configuration list for PBXProject "{APP}" */;
\t\t\tdevelopmentRegion = uk;
\t\t\thasScannedForEncodings = 0;
\t\t\tknownRegions = (
\t\t\t\tuk,
\t\t\t\tBase,
\t\t\t);
\t\t\tmainGroup = {I['maingroup']};
\t\t\tminimizedProjectReferenceProxies = 1;
\t\t\tpreferredProjectObjectVersion = 77;
\t\t\tproductRefGroup = {I['products']} /* Products */;
\t\t\tprojectDirPath = "";
\t\t\tprojectRoot = "";
\t\t\ttargets = (
\t\t\t\t{I['apptarget']} /* {APP} */,
\t\t\t\t{I['testtarget']} /* {TESTS} */,
\t\t\t);
\t\t}};
/* End PBXProject section */

/* Begin PBXResourcesBuildPhase section */
{phase(I['appresources'], 'PBXResourcesBuildPhase', 'Resources')}
{phase(I['testresources'], 'PBXResourcesBuildPhase', 'Resources')}
/* End PBXResourcesBuildPhase section */

/* Begin PBXSourcesBuildPhase section */
{phase(I['appsources'], 'PBXSourcesBuildPhase', 'Sources')}
{phase(I['testsources'], 'PBXSourcesBuildPhase', 'Sources')}
/* End PBXSourcesBuildPhase section */

/* Begin PBXTargetDependency section */
\t\t{I['dependency']} /* PBXTargetDependency */ = {{
\t\t\tisa = PBXTargetDependency;
\t\t\ttarget = {I['apptarget']} /* {APP} */;
\t\t\ttargetProxy = {I['proxy']} /* PBXContainerItemProxy */;
\t\t}};
/* End PBXTargetDependency section */

/* Begin XCBuildConfiguration section */
{cfg(I['projdebug'], 'Debug', proj_debug)}
{cfg(I['projrelease'], 'Release', proj_release)}
{cfg(I['appdebug'], 'Debug', app)}
{cfg(I['apprelease'], 'Release', app)}
{cfg(I['testdebug'], 'Debug', test)}
{cfg(I['testrelease'], 'Release', test)}
/* End XCBuildConfiguration section */

/* Begin XCConfigurationList section */
{cfglist(I['projcfglist'], f'PBXProject "{APP}"', I['projdebug'], I['projrelease'])}
{cfglist(I['appcfglist'], f'PBXNativeTarget "{APP}"', I['appdebug'], I['apprelease'])}
{cfglist(I['testcfglist'], f'PBXNativeTarget "{TESTS}"', I['testdebug'], I['testrelease'])}
/* End XCConfigurationList section */
\t}};
\trootObject = {I['project']} /* Project object */;
}}
"""

scheme = f"""<?xml version="1.0" encoding="UTF-8"?>
<Scheme LastUpgradeVersion = "1640" version = "1.7">
   <BuildAction parallelizeBuildables = "YES" buildImplicitDependencies = "YES" buildArchitectures = "Automatic">
      <BuildActionEntries>
         <BuildActionEntry buildForTesting = "YES" buildForRunning = "YES" buildForProfiling = "YES" buildForArchiving = "YES" buildForAnalyzing = "YES">
            <BuildableReference BuildableIdentifier = "primary" BlueprintIdentifier = "{I['apptarget']}" BuildableName = "{APP}.app" BlueprintName = "{APP}" ReferencedContainer = "container:{APP}.xcodeproj">
            </BuildableReference>
         </BuildActionEntry>
      </BuildActionEntries>
   </BuildAction>
   <TestAction buildConfiguration = "Debug" selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB" shouldUseLaunchSchemeArgsEnv = "YES" shouldAutocreateTestPlan = "YES">
      <Testables>
         <TestableReference skipped = "NO" parallelizable = "NO">
            <BuildableReference BuildableIdentifier = "primary" BlueprintIdentifier = "{I['testtarget']}" BuildableName = "{TESTS}.xctest" BlueprintName = "{TESTS}" ReferencedContainer = "container:{APP}.xcodeproj">
            </BuildableReference>
         </TestableReference>
      </Testables>
   </TestAction>
   <LaunchAction buildConfiguration = "Debug" selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB" launchStyle = "0" useCustomWorkingDirectory = "NO" ignoresPersistentStateOnLaunch = "NO" debugDocumentVersioning = "YES" debugServiceExtension = "internal" allowLocationSimulation = "YES">
      <BuildableProductRunnable runnableDebuggingMode = "0">
         <BuildableReference BuildableIdentifier = "primary" BlueprintIdentifier = "{I['apptarget']}" BuildableName = "{APP}.app" BlueprintName = "{APP}" ReferencedContainer = "container:{APP}.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
   </LaunchAction>
   <ProfileAction buildConfiguration = "Release" shouldUseLaunchSchemeArgsEnv = "YES" savedToolIdentifier = "" useCustomWorkingDirectory = "NO" debugDocumentVersioning = "YES">
      <BuildableProductRunnable runnableDebuggingMode = "0">
         <BuildableReference BuildableIdentifier = "primary" BlueprintIdentifier = "{I['apptarget']}" BuildableName = "{APP}.app" BlueprintName = "{APP}" ReferencedContainer = "container:{APP}.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
   </ProfileAction>
   <AnalyzeAction buildConfiguration = "Debug">
   </AnalyzeAction>
   <ArchiveAction buildConfiguration = "Release" revealArchiveInOrganizer = "YES">
   </ArchiveAction>
</Scheme>
"""

proj = os.path.join(ROOT, f"{APP}.xcodeproj")
os.makedirs(os.path.join(proj, "xcshareddata", "xcschemes"), exist_ok=True)
open(os.path.join(proj, "project.pbxproj"), "w", encoding="utf8").write(pbx)
open(os.path.join(proj, "xcshareddata", "xcschemes", f"{APP}.xcscheme"), "w", encoding="utf8").write(scheme)
print("ok", proj)
