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

{ #category : '*HVH-Replication' }
CooHistoryExperimentRunner >> benchmarksForSession: aSession [
	"Original method of the benchmark (commit 55032e8 of branch better), without the History after
	self configuration. Every strategy answers the same call sites. The history strategies read the
	snapshot, not the session: while a commit is benchmarked they only know the history of the
	previous commits."

	| benchmarks |
	benchmarks := OrderedDictionary new.
	{
		#Baseline -> { self completeBaselineMessageBuilder. self completeBaselineVariableBuilder }.
		#Semantic -> { self completeSemanticsMessageBuilder. self completeSemanticsVariableBuilder }.
		#History -> {
			(self historyMessageBuilderWithSession: historySnapshot).
			(self historyVariableBuilderWithSession: historySnapshot) }.
		#Dependency -> {
			self completeDirectDependencyMessageBuilder.
			self completeDirectDependencyVariableBuilder }.
		#Hybrid -> {
			(self hybridMessageBuilderWithSession: historySnapshot).
			(self hybridVariableBuilderWithSession: historySnapshot) }.
		#HybridHD -> {
			(self hybridHDMessageBuilderWithSession: historySnapshot).
			(self hybridVariableBuilderWithSession: historySnapshot) }.
		#HybridDH -> {
			(self hybridDHMessageBuilderWithSession: historySnapshot).
			(self hybridDHVariableBuilderWithSession: historySnapshot) } } do: [ :strategy |
		benchmarks
			at: #message -> strategy key
			put: (self
					 benchmark: CooStaticBenchmarksMessageHistory
					 named: strategy key
					 builder: strategy value first
					 session: aSession);
			at: #variable -> strategy key
			put: (self
					 benchmark: CooStaticBenchmarksVariableHistory
					 named: strategy key
					 builder: strategy value second
					 session: aSession) ].
	^ benchmarks
]
