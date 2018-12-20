all:
	$(MAKE) -C user
	$(MAKE) -C kernel

.PHONY: clean
clean:
	$(MAKE) -C user clean
	$(MAKE) -C kernel clean
