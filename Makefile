all:
	$(MAKE) -C init
	$(MAKE) -C sh
	$(MAKE) -C kernel

.PHONY: clean
clean:
	$(MAKE) -C init clean
	$(MAKE) -C sh clean
	$(MAKE) -C kernel clean
