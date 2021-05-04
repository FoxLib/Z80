all:
	# Создать первичный TAP-файл
	bas2tap -q starter.bas -sUNDERTALE ut.tap

	# Дописать коды
	php make.php

	# Тест
	mv ut.tap ../..
	cd ../.. && vmzx 48k.z80 ut.tap
