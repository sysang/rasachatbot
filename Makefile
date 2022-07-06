SHELL=/bin/zsh
.SILENT: help

help:
	echo "Commands:"
	echo "- train"
	echo "- test"
	echo "- dryrun"

tensorboard:
	./tensorboard.sh

testrasachatbot:
	docker exec ailab zsh -c 'TIMESTAMP="$(shell date +%Y%m%d\[\]%H%M%S)" && cd /workspace/rasachatbot/botserver-app && rasa test core --out="results/$$TIMESTAMP"'

tensorboard_dir := botserver-app/tensorboard/current
log_dir = botserver-app/tensorboard/$(shell date +%Y%m%d-%H%M%S)/
trainrasachatbot:
	test -d $(tensorboard_dir) && mv $(tensorboard_dir) $(log_dir) || echo 'Do not need to move current dir.'
	mkdir -p $(tensorboard_dir) && chmod 777 $(tensorboard_dir)
	docker exec ailab zsh -c 'cd /workspace/rasachatbot/botserver-app && rasa train --augmentation 0 -v'

restartcontainers:
	docker restart rasachatbot-rasa-x-1 && docker restart rasachatbot-action-server-1

train: trainrasachatbot restartcontainers

core:
	docker exec ailab zsh -c 'cd /workspace/rasachatbot/botserver-app && rasa train core --augmentation 0 -v'

dryrun:
	docker exec ailab zsh -c 'cd /workspace/rasachatbot/botserver-app && rasa train --dry-run'

test:
	cd botserver-app && python test_runner.py --model=$(model) --testfile=$(testfile)

testall:
	make query_hotel_room_schema_test model=$(M)
	make query_hotel_room_chitchat_faq_test model=$(M)
	make query_hotel_room_chitchat_nlufallback_test model=$(M)
	make query_hotel_room_chitchat_outofscope_test model=$(M)
	make query_hotel_room_chitchat_revisebkinfo_test model=$(M)
	make query_hotel_room_chitchat_smalltalk_test model=$(M)
	make query_hotel_room_donecollecting_revisebkinfo_test model=$(M)

query_hotel_room_schema_test:
	export testfile=query_hotel_room_schema; \
	make test testfile=$$testfile model=$(M)

query_hotel_room_chitchat_faq_test:
	export testfile=query_hotel_room_chitchat_faq; \
	make test testfile=$$testfile model=$(M)

query_hotel_room_chitchat_nlufallback_test:
	export testfile=query_hotel_room_chitchat_nlufallback; \
	make test testfile=$$testfile model=$(M)

query_hotel_room_chitchat_outofscope_test:
	export testfile=query_hotel_room_chitchat_outofscope; \
	make test testfile=$$testfile model=$(M)

query_hotel_room_chitchat_revisebkinfo_test:
	export testfile=query_hotel_room_chitchat_revisebkinfo; \
	make test testfile=$$testfile model=$(M)

query_hotel_room_chitchat_smalltalk_test:
	export testfile=query_hotel_room_chitchat_smalltalk; \
	make test testfile=$$testfile model=$(M)

query_hotel_room_donecollecting_revisebkinfo_test:
	export testfile=query_hotel_room_donecollecting_revisebkinfo; \
	make test testfile=$$testfile model=$(M)

query_hotel_room_revise_invalid_bkinfo_test:
	export testfile=query_hotel_room_revise_invalid_bkinfo; \
	make test testfile=$$testfile model=$(M)

copyaddons:
	docker cp botserver-app/addons/custom_slot_types.py rasachatbot-rasa-production-1:/app/addons/

test_actions_fsm_botmemo_booking_progress:
	docker exec rasachatbot-action-server-1 bash -c 'python -c "from actions.fsm_botmemo_booking_progress import __test__; __test__();"'

test_actions_duckling_service:
	docker exec rasachatbot-action-server-1 bash -c 'python -c "from actions.duckling_service import __test__; __test__();"'

test_actions_booking_service:
	docker exec rasachatbot-action-server-1 bash -c 'export TEST_FUNC=$(tfunc) && python -c "$$(grep  --regexp=__pytest__ -A 1 actions/booking_service.py | tail -n 1)"'

# files := file1 file2
# some_file: $(files)
# 	echo "Look at this variable: " $(files)
# 	touch some_file

# file1:
# 	touch file1
# file2:
# 	touch file2
