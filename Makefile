all:
	$(MAKE) -C common
	$(MAKE) -C lib
	$(MAKE) -C init
	$(MAKE) -C sh
	$(MAKE) -C ls
	$(MAKE) -C kernel

.PHONY: clean
clean:
	$(MAKE) -C common clean
	$(MAKE) -C lib clean
	$(MAKE) -C init clean
	$(MAKE) -C sh clean
	$(MAKE) -C ls clean
	$(MAKE) -C kernel clean
