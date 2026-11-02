"Build the benchmark image from the pinned local clones (@HCH@, @HCB@ and @PKG@ are replaced by
bin/prepare.sh):
  1. the dependency ExtendedHeuristicCompletionBenchmarks, from its pinned clone, then locked so that
     the github://...HeuristicCompletion-Benchmarks:main reference of the benchmark baseline does not
     fetch the current main branch;
  2. the benchmark, group Bench;
  3. the replication additions (HVH-Replication)."
[
Metacello new
	baseline: 'ExtendedHeuristicCompletionBenchmarks';
	repository: 'tonel://@HCB@/src';
	onConflict: [ :e | e useIncoming ];
	onUpgrade: [ :e | e useIncoming ];
	load.
Metacello new
	baseline: 'ExtendedHeuristicCompletionBenchmarks';
	repository: 'tonel://@HCB@/src';
	lock.
Metacello new
	baseline: 'ExtendedHeuristicCompletionHistory';
	repository: 'tonel://@HCH@/src';
	onConflict: [ :e | e useIncoming ];
	onUpgrade: [ :e | e useIncoming ];
	onLock: [ :e | e honor ];
	load: #( 'Bench' ).
Metacello new
	baseline: 'HvhReplication';
	repository: 'tonel://@PKG@/pharo/src';
	load ]
		on: Warning
		do: [ :w | w resume: true ].

((Smalltalk globals includesKey: #HvhReplication)
	and: [ (Smalltalk globals includesKey: #CooHistoryExperimentRunner)
	and: [ (Smalltalk globals includesKey: #CooBenchRunner)
	and: [ ((Smalltalk globals at: #CooCallsiteLog) includesSelector: #hvhSuspend) ] ] ])
		ifTrue: [ Stdio stdout nextPutAll: 'BASE IMAGE OK'; lf; flush ]
		ifFalse: [ Stdio stdout nextPutAll: 'BASE IMAGE BROKEN'; lf; flush. Smalltalk exitFailure ].
