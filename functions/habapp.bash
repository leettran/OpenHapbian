#!/usr/bin/env bash
# shellcheck disable=SC2181

## Function for installing HABApp (python3 rule engine)
## Valid arguments: "install" or "remove"
##
##    habapp_setup()
##
habapp_setup() {
  local installFolder="/opt"
  local venvName="habapp"
  local configFolder="/etc/openhab/habapp"

  if [[ $1 == "remove" ]]; then
    echo -n "$(timestamp) [openHABian] Removing HABApp service ... "
    if ! cond_redirect systemctl disable --now habapp.service; then echo "FAILED (disable service)"; return 1; fi
    if ! rm -f /etc/systemd/system/habapp.service; then echo "FAILED (remove service)"; return 1; fi
    if cond_redirect systemctl -q daemon-reload &> /dev/null; then echo "OK"; else  echo "FAILED (daemon-reload)"; return 1; fi

    echo -n "$(timestamp) [openHABian] Uninstalling HABApp ... "
    if rm -rf "${installFolder:?}/${venvName:?}/"; then echo "OK"; else echo "FAILED"; return 1; fi

    if [[ -n "$INTERACTIVE" ]]; then
      whiptail --title "HABApp removed" --msgbox "We permanently removed the HABApp installation from your system." 7 80
    fi
    return 0;
  fi
  if [[ $1 != "install" ]]; then return 1; fi

  echo -n "$(timestamp) [openHABian] Installing HABApp prerequisites (pip, venv) ... "
  if cond_redirect apt-get install --yes python3-pip python3-dev python3-venv; then echo "OK"; else echo "FAILED"; return 1; fi

  echo -n "$(timestamp) [openHABian] Creating venv ... "
  if ! cond_redirect cd "$installFolder"; then echo "FAILED"; return 1; fi
  if cond_redirect python3 -m venv "$venvName"; then echo "OK"; else echo "FAILED"; return 1; fi
  
  echo -n "$(timestamp) [openHABian] Installing HABApp ... "
  if ! cond_redirect cd "$venvName"; then echo "FAILED"; return 1; fi
  if ! cond_redirect source bin/activate; then echo "FAILED"; return 1; fi

  if ! cond_redirect python3 -m pip install --upgrade pip habapp; then echo "FAILED"; return 1; fi
  if cond_redirect deactivate; then echo "OK"; else echo "FAILED"; return 1; fi

  echo -n "$(timestamp) [openHABian] Creating HABApp configuration folder ... "
  if ! cond_redirect mkdir -p "$configFolder"; then echo "FAILED"; return 1; fi
  if ! cond_redirect chown -R openhab:openhabian "$configFolder"; then echo "FAILED"; return 1; fi
  if cond_redirect chmod -R 775 "$configFolder"; then echo "OK"; else echo "FAILED"; return 1; fi

  echo -n "$(timestamp) [openHABian] Setting up HABApp as a service ... "
  if ! cond_redirect install -m 644 "${BASEDIR:-/opt/openhabian}"/includes/habapp.service /etc/systemd/system/habapp.service; then echo "FAILED (copy service)"; return 1; fi
  if ! cond_redirect systemctl -q daemon-reload &> /dev/null; then echo "FAILED (daemon-reload)"; return 1; fi
  if cond_redirect systemctl enable --now habapp.service; then echo "OK"; else echo "FAILED (enable service)"; return 1; fi
  
  if [[ -n "$INTERACTIVE" ]]; then
    whiptail --title "HABApp installed" --msgbox "HABApp was successfully installed on your system. A folder 'habapp' was created inside your openHAB configuration folder." 8 80
  fi
}
