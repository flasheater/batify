SHELL := /bin/bash

UDEVDIR = $(DESTDIR)/etc/udev/rules.d
BINDIR  = $(DESTDIR)/usr/local/bin
ICONDIR = $(DESTDIR)/usr/share/icons

UDEV    = 99-$(shell basename $(basename $(SRC))).rules
SRC     = src/batify.sh

all:$(UDEV)

$(UDEV):
	@echo -e 'ACTION=="change", KERNEL=="BAT0", \\'                       >  $(UDEV)
	@echo -e 'SUBSYSTEM=="power_supply", \\'                              >> $(UDEV)
	@echo -e 'ATTR{status}=="Discharging", \\'                            >> $(UDEV)
	@echo -e 'RUN+="/usr/local/bin/batify.sh %k $$attr{capacity} none"\n' >> $(UDEV)
	@echo -e 'SUBSYSTEM=="power_supply", ACTION=="change", \\'            >> $(UDEV)
	@echo -e 'ENV{POWER_SUPPLY_ONLINE}=="0", ENV{POWER}="off", \\'        >> $(UDEV)
	@echo -e 'OPTIONS+="last_rule", \\'                                   >> $(UDEV)
	@echo -e 'RUN+="/usr/local/bin/batify.sh none none 0"\n'              >> $(UDEV)
	@echo -e 'SUBSYSTEM=="power_supply", ACTION=="change", \\'            >> $(UDEV)
	@echo -e 'ENV{POWER_SUPPLY_ONLINE}=="1", ENV{POWER}="on", \\'         >> $(UDEV)
	@echo -e 'OPTIONS+="last_rule", \\'                                   >> $(UDEV)
	@echo -e 'RUN+="/usr/local/bin/batify.sh none none 1"'                >> $(UDEV)

install: all
	mkdir -p $(UDEVDIR)
	mkdir -p $(ICONDIR)
	mkdir -p $(BINDIR)
	cp -r icons $(ICONDIR)/batify
	cp $(UDEV) $(UDEVDIR)/$(UDEV)
	cp $(SRC) $(BINDIR)/$(shell basename $(SRC))

uninstall:
	$(RM) -r $(ICONDIR)/batify
	$(RM) $(UDEVDIR)/$(UDEV)
	$(RM) $(BINDIR)/$(shell basename $(SRC))

.PHONY: all install uninstall
