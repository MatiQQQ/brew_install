#!/bin/zsh

CPU_ARCH=$(uname -m)
USER_TARGET=$(scutil <<<"show State:/Users/ConsoleUser" | awk '/Name :/ && ! /loginwindow/ { print $3 }')

echo $USER_TARGET

if [[ "$CPU_ARCH" == "arm64" ]]; then
    # M1/arm64 machines
    HOMEBREW_PREFIX="/opt/homebrew"
else
    # Intel machines
    HOMEBREW_PREFIX="/usr/local"
fi

echo "Checking Command Line Tools for Xcode"
xcode-select -p &>/dev/null

if [[ $? != 0 ]]; then
    # This temporary file prompts the 'softwareupdate' utility to list the Command Line Tools
    touch /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress
    PROD=$(softwareupdate -l | grep "\*.*Command Line" | tail -n 1 | sed 's/^[^C]* //')
    softwareupdate -i "$PROD"
    rm -f /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress
    /usr/bin/xcode-select --switch /Library/Developer/CommandLineTools
fi

if [[ -e "${HOMEBREW_PREFIX}/bin/brew" ]]; then
    su -l "${USER_TARGET}" -c "${HOMEBREW_PREFIX}/bin/brew update"
    exit 0
fi

if [[ ! -e "${HOMEBREW_PREFIX}/bin/brew" ]]; then
    mkdir -p "${HOMEBREW_PREFIX}/Homebrew"

    curl -L https://github.com/Homebrew/brew/tarball/master | tar xz --strip 1 -C "${HOMEBREW_PREFIX}/Homebrew"

    # Manually make all the appropriate directories and set permissions
    mkdir -p "${HOMEBREW_PREFIX}/Cellar" "${HOMEBREW_PREFIX}/Homebrew"
    mkdir -p "${HOMEBREW_PREFIX}/Caskroom" "${HOMEBREW_PREFIX}/Frameworks" "${HOMEBREW_PREFIX}/bin"
    mkdir -p "${HOMEBREW_PREFIX}/include" "${HOMEBREW_PREFIX}/lib" "${HOMEBREW_PREFIX}/opt" "${HOMEBREW_PREFIX}/etc" "${HOMEBREW_PREFIX}/sbin"
    mkdir -p "${HOMEBREW_PREFIX}/share/zsh/site-functions" "${HOMEBREW_PREFIX}/var"
    mkdir -p "${HOMEBREW_PREFIX}/share/doc" "${HOMEBREW_PREFIX}/man/man1" "${HOMEBREW_PREFIX}/share/man/man1"
    mkdir -p "${HOMEBREW_PREFIX}/var/homebrew/linked"

    chown -R "${USER_TARGET}":staff "${HOMEBREW_PREFIX}/Cellar"
    chown -R "${USER_TARGET}":staff "${HOMEBREW_PREFIX}/Homebrew"
    chown -R "${USER_TARGET}":staff "${HOMEBREW_PREFIX}/Caskroom"
    chown -R "${USER_TARGET}":staff "${HOMEBREW_PREFIX}/Frameworks"
    chown -R "${USER_TARGET}":staff "${HOMEBREW_PREFIX}/bin"
    chown -R "${USER_TARGET}":staff "${HOMEBREW_PREFIX}/include"
    chown -R "${USER_TARGET}":staff "${HOMEBREW_PREFIX}/lib"
    chown -R "${USER_TARGET}":staff "${HOMEBREW_PREFIX}/opt"
    chown -R "${USER_TARGET}":staff "${HOMEBREW_PREFIX}/etc"
    chown -R "${USER_TARGET}":staff "${HOMEBREW_PREFIX}/sbin"
    chown -R "${USER_TARGET}":staff "${HOMEBREW_PREFIX}/share"
    chown -R "${USER_TARGET}":staff "${HOMEBREW_PREFIX}/var"
    chown -R "${USER_TARGET}":staff "${HOMEBREW_PREFIX}/man"
    chown -R "${USER_TARGET}":staff "${HOMEBREW_PREFIX}/var/homebrew/linked"

    chmod -R g+rwx "${HOMEBREW_PREFIX}/*"
    chmod 755 "${HOMEBREW_PREFIX}/share/zsh" "${HOMEBREW_PREFIX}/share/zsh/site-functions"

    mkdir -p /Library/Caches/Homebrew
    chmod g+rwx /Library/Caches/Homebrew
    chown "${USER_TARGET}:staff" /Library/Caches/Homebrew

    ln -s "${HOMEBREW_PREFIX}/Homebrew/bin/brew" "${HOMEBREW_PREFIX}/bin/brew"

    su -l "$USER_TARGET" -c "${HOMEBREW_PREFIX}/bin/brew install md5sha1sum"
    echo "export PATH=\"${HOMEBREW_PREFIX}/opt/openssl/bin:\$PATH\"" |
        tee -a /Users/${USER_TARGET}/.bash_profile /Users/${USER_TARGET}/.zprofile
    chown ${USER_TARGET} /Users/${USER_TARGET}/.bash_profile /Users/${USER_TARGET}/.zprofile

    su -l "$USER_TARGET" -c "${HOMEBREW_PREFIX}/bin/brew update" 2>&1

    if [[ "$CPU_ARCH" == "arm64" ]]; then
        echo 'eval $(/opt/homebrew/bin/brew shellenv)' >>/Users/${USER_TARGET}/.zprofile
    fi
fi
