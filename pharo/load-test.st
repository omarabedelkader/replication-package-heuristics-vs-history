"Load test of one project configuration (@PROJECT@ is replaced by bin/load-test.sh). It does what the
start of a run does: loads the project with its configuration's loader, finds its repository and the
commits to replay (CooHistoryExperimentRunner>>#loadCommitsAndBench:session:), then prints one line:
  LOADTEST OK <project> commits=<replayable>/<window> packages=<n> <first package names>
  LOADTEST FAIL <project>: <reason>
No call site is completed: it only tells whether the project can be run, and how long its replay is."
[
	[
		| configuration commits packages usable |
		Iceberg remoteTypeSelector: #httpsUrl.
		configuration := CooHistoryExperimentConfiguration perform: #@PROJECT@.
		configuration repository: (HvhReplication httpsUrlFor: configuration repository).
		configuration loadProject.
		commits := (HistoryPopulatorForBench repositoryNamed: configuration repository)
			           commitsForHead: configuration numberOfCommits.
		packages := ((commits first repository workingCopy packages select: [ :each | each isLoaded ])
			             collect: [ :each | each name ]) reject: [ :each | each beginsWith: 'BaselineOf' ].
		"As CooHistoryExperimentRunner>>#commitsContainingProjectPackages:, newest first."
		usable := commits findFirst: [ :commit |
			          | names |
			          names := (commit packages collect: [ :each | each name ]) asSet.
			          packages noneSatisfy: [ :each | names includes: each ] ].
		usable := usable = 0
			          ifTrue: [ commits size ]
			          ifFalse: [ usable - 1 ].
		Stdio stdout
			nextPutAll: 'LOADTEST ';
			nextPutAll: ((packages isEmpty or: [ usable < 2 ]) ifTrue: [ 'FAIL' ] ifFalse: [ 'OK' ]);
			nextPutAll: ' @PROJECT@ commits=' , usable printString , '/' , commits size printString;
			nextPutAll: ' packages=' , packages size printString , ' ';
			nextPutAll: (' ' join: (packages asArray first: (packages size min: 6)));
			lf;
			flush.
		(packages isEmpty or: [ usable < 2 ])
			ifTrue: [ Smalltalk exitFailure ]
			ifFalse: [ Smalltalk exitSuccess ] ]
		on: Warning
		do: [ :warning | warning resume: true ] ]
	on: Error
	do: [ :error |
		Stdio stdout
			nextPutAll: 'LOADTEST FAIL @PROJECT@: ' , error class name , ' ' , error messageText asString;
			lf;
			flush.
		Smalltalk exitFailure ]
