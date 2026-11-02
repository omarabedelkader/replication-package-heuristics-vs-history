Extension { #name : 'CooHistoryExperimentRunner' }

{ #category : '*HVH-Replication' }
CooHistoryExperimentRunner >> replayCommits: commits session: aSession benchmarks: benchmarks [
	"Original method of the benchmark (commit 55032e8 of branch better), plus a progress line and a
	checkpoint between two commits."

	commits reversed withIndexDo: [ :commit :index |
		| loadSuccess |
		historySnapshot updateFrom: aSession.
		loadSuccess := true.
		[ self loadFromOldToNewCommit: commit ]
			on: Error
			do: [ :error |
				loadSuccess := false.
				statistics recordFailedCommit.
				Transcript
					cr;
					show: 'Error loading ' , commit printString;
					show: ': ' , error messageText ].
		[
			loadSuccess ifTrue: [
				log commit: commit index: index.
				benchmarks do: [ :benchmark | benchmark run ].
				statistics collectHistoryStatisticsFrom: aSession.
				statistics recordSuccessfulCommit ]
		] ensure: [
			"Clear per-commit events even after a partial checkout or benchmark error.
			The history handlers continue to accumulate across commits."
			aSession resetDevelopmentItems ].
		HvhReplication log: 'Commit ' , index printString , '/' , commits size printString , ' done'.
		HvhReplication checkpointIfDueWith: log ]
]
