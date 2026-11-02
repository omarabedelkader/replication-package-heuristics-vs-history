Extension { #name : 'CooStaticBenchmarksVariableHistory' }

{ #category : '*HVH-Replication' }
CooStaticBenchmarksVariableHistory >> benchCallsite: aVariable atPosition: aPosition [
	"Original method of the benchmark (commit 55032e8), plus the guard that leaves the call site to
	another unit of the project (see HvhReplication class>>#benches:id:)."

	| oldName |
	log ifNotNil: [
		(HvhReplication benches: self name id: (log idFor: aVariable target: aVariable name asSymbol))
			ifFalse: [ ^ self ] ].
	oldName := aVariable name.
	2 to: (self maxPrefixSizeFor: aVariable) do: [ :index |
		| prefix startTime startMemory completion candidates completionIndex |
		startTime := self startTimeMeasurement.
		startMemory := self startMemoryMeasurement.
		prefix := self extractPrefixFrom: oldName at: index.
		aVariable name: prefix.
		completion := self buildCompletionFor: aVariable atPosition: aPosition.
		candidates := self fetchTopCandidatesFrom: completion usingPrefix: prefix.
		completionIndex := self findCompletionIndexFor: oldName inCandidates: candidates.
		self trackCompletionResultsFor: oldName atIndex: completionIndex withPrefix: prefix.
		log ifNotNil: [
			log
				recordKind: #variable
				strategy: self name
				node: aVariable
				target: oldName asSymbol
				prefix: prefix size
				rank: completionIndex
				milliseconds: Time millisecondClockValue - startTime ].
		self logMemoryUsageSince: startMemory forPrefixSize: prefix size.
		self logExecutionTimeSince: startTime forPrefixSize: prefix size ].
	aVariable name: oldName
]
