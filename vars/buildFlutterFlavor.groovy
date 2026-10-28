// buildFlutterFlavor.groovy — Jenkins shared library step.
//
// Thin wrapper that validates inputs, injects credentials via withCredentials,
// and delegates the actual build to .ci/scripts/build_<platform>.sh. All real
// build logic lives in shell so it can be reproduced locally.
//
// Usage in a Jenkinsfile:
//   buildFlutterFlavor(
//     platform: 'android',          // 'android' | 'ios'
//     flavor: 'qa',                 // 'qa' | 'int' | 'prod'
//     buildType: 'release',         // 'debug' | 'release'
//     buildNumber: env.BUILD_NUMBER,
//     gitSha: env.GIT_COMMIT.take(7),
//     artifactSuffix: "qa-release-${env.BUILD_NUMBER}"
//   )
//
// TODO: confirm Jenkins credential IDs ('android-keystore', 'android-keystore-passwords',
// 'ios-signing-cert', 'ios-provisioning-int') match what's configured in Jenkins.

def call(Map config) {
    validateConfig(config)

    String cmd = ".ci/scripts/build_${config.platform}.sh " +
                 "--flavor='${config.flavor}' " +
                 "--build-type='${config.buildType}' " +
                 "--build-number='${config.buildNumber}' " +
                 "--git-sha='${config.gitSha}' " +
                 "--suffix='${config.artifactSuffix}'"

    if (config.platform == 'android' && config.buildType == 'release') {
        withCredentials([
            file(credentialsId: 'android-keystore', variable: 'KEYSTORE_FILE'),
            usernamePassword(
                credentialsId: 'android-keystore-passwords',
                usernameVariable: 'KEY_ALIAS',
                passwordVariable: 'KEYSTORE_PASSWORD'
            ),
            string(credentialsId: 'android-key-password', variable: 'KEY_PASSWORD')
        ]) {
            sh cmd
        }
    } else if (config.platform == 'ios' && config.buildType == 'release') {
        withCredentials([
            file(credentialsId: "ios-signing-cert-${config.flavor}", variable: 'P12_FILE'),
            string(credentialsId: "ios-signing-cert-password-${config.flavor}", variable: 'P12_PASSWORD'),
            file(credentialsId: "ios-provisioning-${config.flavor}", variable: 'PROVISIONING_PROFILE')
        ]) {
            try {
                sh '.ci/scripts/ios_keychain_setup.sh "$P12_FILE" "$P12_PASSWORD" "$PROVISIONING_PROFILE"'
                sh cmd
            } finally {
                sh '.ci/scripts/ios_keychain_teardown.sh || true'
            }
        }
    } else {
        sh cmd
    }
}

private void validateConfig(Map c) {
    def required = ['platform', 'flavor', 'buildType', 'buildNumber', 'gitSha', 'artifactSuffix']
    def missing = required.findAll { !c.containsKey(it) || c[it] == null || c[it].toString().isEmpty() }
    if (missing) {
        error("buildFlutterFlavor: missing required config: ${missing.join(', ')}")
    }
    if (!(c.platform in ['android', 'ios'])) {
        error("buildFlutterFlavor: invalid platform '${c.platform}' — must be 'android' or 'ios'")
    }
    if (!(c.flavor in ['qa', 'int', 'prod'])) {
        error("buildFlutterFlavor: invalid flavor '${c.flavor}' — must be 'qa', 'int', or 'prod'")
    }
    if (!(c.buildType in ['debug', 'release'])) {
        error("buildFlutterFlavor: invalid buildType '${c.buildType}' — must be 'debug' or 'release'")
    }
}

// Placeholder — real distribution (Firebase App Distribution / internal store API)
// is a follow-up task. For now, log what would be sent.
def distributeInternal(Map config) {
    echo "[distributeInternal placeholder] would distribute " +
         "flavor=${config.flavor} buildType=${config.buildType} " +
         "to group=${config.testerGroup}"
}

// Placeholder — Teams/Slack notifications not implemented yet.
def notifyTeams(Map config) {
    echo "[notifyTeams placeholder] status=${config.status} build=${config.buildNumber}"
}
