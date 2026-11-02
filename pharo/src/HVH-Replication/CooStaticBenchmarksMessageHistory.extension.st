Extension { #name : 'CooStaticBenchmarksMessageHistory' }

{ #category : '*HVH-Replication' }
CooStaticBenchmarksMessageHistory >> benchCallsite: aMessageNode atPosition: aPosition [
	"Original method of the benchmark (commit 55032e8), plus the guard that leaves the call site to
	another unit of the project (see HvhReplication class>>#benches:id:)."

	| originalSelector |
	log ifNotNil: [
		(HvhReplication benches: self name id: (log idFor: aMessageNode target: aMessageNode selectorNode value))
			ifFalse: [ ^ self ] ].
	originalSelector := aMessageNode selectorNode value.
	2 to: (self maxPrefixSizeFor: originalSelector) do: [ :index |
		| prefix startTime startMemory completion candidates completionIndex |
		startTime := self startTimeMeasurement.
		startMemory := self startMemoryMeasurement.
		prefix := self extractPrefixFrom: originalSelector at: index.
		aMessageNode selectorNode value: prefix.
		completion := self buildCompletionFor: aMessageNode atPosition: aPosition.
		candidates := self fetchTopCandidatesFrom: completion usingPrefix: prefix.
		completionIndex := self findCompletionIndexFor: originalSelector inCandidates: candidates.
		self trackCompletionResultsFor: originalSelector atIndex: completionIndex withPrefix: prefix.
		log ifNotNil: [
			log
				recordKind: #message
				strategy: self name
				node: aMessageNode
				target: originalSelector
				prefix: prefix size
				rank: completionIndex
				milliseconds: Time millisecondClockValue - startTime ].
		self logMemoryUsageSince: startMemory forPrefixSize: prefix size.
		self logExecutionTimeSince: startTime forPrefixSize: prefix size ].
	aMessageNode selectorNode value: originalSelector
]
