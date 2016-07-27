name=sbxlogon

MAKEFLAGS += --warn-undefined-variables

GIT = git
MAKENSIS = makensis
RM = rm -f
UNIX2DOS = unix2dos

include VERSION.mk
version=$(majorv).$(minorv).$(microv).$(qualifierv)
version_short=$(version)

ifeq ($(qualifierv),0)
	version_short=$(majorv).$(minorv).$(microv)
	ifeq ($(microv),0)
		version_short=$(majorv).$(minorv)
	endif
endif

PRINT_DIR =
ifneq ($(findstring $(MAKEFLAGS),w),w)
	PRINT_DIR = --no-print-directory
endif

MAKENSIS_SW  =
QUIET_MAKENSIS =
QUIET_GEN =
QUIET_UNIX2DOS =
ifneq ($(findstring $(MAKEFLAGS),s),s)
ifndef V
	QUIET_MAKENSIS = @echo '   ' MAKENSIS $@;
	QUIET_UNIX2DOS = @echo '   ' UNIX2DOS $@;
	QUIET_GEN      = @echo '   ' GEN $@;
	export V

	UNIX2DOS += --quiet
	MAKENSIS_SW += /V2
endif
endif

installer=$(name)_$(version_short).exe

changelog=$(installer)-changelog.txt

MAKENSIS_SW += /Doutfile=$(installer)
MAKENSIS_SW += /Dname="$(name)"
MAKENSIS_SW += /Dversion=$(version)

$(installer): StreamboxLogonSettings.xml
$(installer): include.ps1
$(installer): settings.ps1
$(installer): install.nsi
	$(QUIET_MAKENSIS)$(MAKENSIS) $(MAKENSIS_SW) $<

test: $(installer)
	cmd /c $(installer)

changelog: $(changelog)
$(changelog):
	$(QUIET_GEN)$(GIT) log -m --abbrev-commit --pretty=tformat:'%h %ad %s' --date=short >$@
	$(QUIET_UNIX2DOS)$(UNIX2DOS) $@

debug: $(installer)
	cmd /c $(installer) /debug

PS_SW =
PS_SW += -version 1
PS_SW += -noprofile
PS_SW += -executionpolicy unrestricted
PS_SW += -inputformat none

test2:
	powershell $(PS_SW) -file settings.ps1 -ws7e

export_task:
	schtasks /query /xml /tn StreamboxLogonSettings >StreamboxLogonSettings.xml

check:
	cmd /c start taskschd.msc

clean:
	$(RM) $(installer)
	$(RM) Uninstall.bat
	$(RM) $(changelog)
