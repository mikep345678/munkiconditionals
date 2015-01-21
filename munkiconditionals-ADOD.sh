#!/bin/sh

SCRIPT_VERSION="20150119.01"
SCRIPT_STAMP="munkiconditionals-ADOD"


# munkiconditionals.sh
# this script should reside in /usr/local/munki/conditions where it is called at every run of managedsoftwareupdate

# define where dsgrouputil is installed. dsgrouputil is available from https://github.com/jatoben/dsgrouputil
dsgu="/usr/local/bin/dsgrouputil"

# Read the location of the ManagedInstallDir from ManagedInstall.plist (if using MCX, read Managed\ Preferences/ManagedInstalls)

#managedinstalldir="$(defaults read /Library/Preferences/ManagedInstalls ManagedInstallDir)"
managedinstalldir="$(defaults read /Library/Managed\ Preferences/ManagedInstalls ManagedInstallDir)"

# determine machine's LDAP search server
ldapserver=$( dscl localhost -read /Search | grep -m 1 LDAP )

# define Active Directory tree
AD="/Active Directory/AD/All Domains"

# Make sure we're outputting our information to "ConditionalItems.plist" (plist is left off since defaults requires this)
plist_loc="$managedinstalldir/ConditionalItems"

# Gather list of all OD groups, peeling out only those that include the text "munkiapp".
# My OD policy groups follow a naming scheme like -pol_comp_munkiapp_office and -pol_comp_munkiapp_adobecs5
appgroups-OD=$( dscl $ldapserver -list /ComputerGroups | grep "munkiapp" )
appgroups-AD=$( dscl "$AD" -list Groups | grep "munkiapp" )

# OD
# Build list of assigned applications by querying OD group membership of current computer 
for app in $appgroups-OD
do
	if $dsgu -q 1 -o checkmember -t computer -currentHost 1 -g $app; then
		assignedapps+=( $app )
		echo $assignedapps
	fi
done

# AD
# Build ist

# Note the key "assignedapps" which becomes the condition that you would use in a predicate statement
defaults write "$plist_loc" "assignedapps" -array "${assignedapps[@]}"

# CRITICAL! Since 'defaults' outputs a binary plist, we need to ensure that munki can read it by converting it to xml
plutil -convert xml1 "$plist_loc".plist

exit 0