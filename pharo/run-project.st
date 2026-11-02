"One History experiment. @PROJECT@ and @OUTPUT@ are replaced by bin/run.sh.
The image is quit explicitly: after a checkpoint, this code goes on in a reopened image whose own
command line no longer says --quit."
[
	HvhReplication runConfigurationNamed: #@PROJECT@ outputDirectory: '@OUTPUT@'.
	HvhReplication log: 'Experiment finished'.
	Smalltalk exitSuccess ]
		on: Error
		do: [ :e |
			Stdio stderr nextPutAll: 'Experiment failed: ', e description; lf.
			(e signalerContext stack first: (e signalerContext stack size min: 25))
				do: [ :context | Stdio stderr nextPutAll: context printString; lf ].
			Stdio stderr flush.
			Smalltalk exitFailure ].
