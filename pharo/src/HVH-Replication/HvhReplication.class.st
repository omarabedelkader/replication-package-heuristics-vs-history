"
Replication-package additions to the History benchmark. They change nothing in what is measured;
they only:
  1. clone every repository over HTTPS, so no SSH key is needed on the compute nodes;
  2. save the image between two commits of the replay (a checkpoint). A job that hits its walltime
     is continued by reopening that image: the replay process carries on at the next commit, with
     the same session, history snapshot, statistics and benchmarks.

Environment variables, read at every commit:
  HVH_CHECKPOINT_MINUTES  minutes between two checkpoints (default 30)
  HVH_CHECKPOINT_REQUEST  a file: touching it asks for a checkpoint after the current commit
  HVH_CHECKPOINT_HOOK     a shell command run after each checkpoint (archives it to persistent storage)
"
Class {
	#name : 'HvhReplication',
	#superclass : 'Object',
	#classVars : [
		'LastCheckpoint',
		'LogFiles'
	],
	#category : 'HVH-Replication',
	#package : 'HVH-Replication'
}

{ #category : 'checkpoint' }
HvhReplication class >> checkpointIfDueWith: aLog [

	self isDue ifTrue: [ self checkpointWith: aLog ]
]

{ #category : 'checkpoint' }
HvhReplication class >> checkpointWith: aLog [
	"Save the image. Execution continues right after the snapshot twice: now, and every time the
	saved image is reopened. Only now is the hook run, to archive the fresh checkpoint."

	| session hook start dangling |
	start := DateAndTime now.
	aLog hvhSuspend.
	dangling := self removeDanglingSessionHandlers.
	session := Smalltalk session.
	Smalltalk snapshot: true andQuit: false.
	self restoreSessionHandlers: dangling.
	LastCheckpoint := DateAndTime now.
	aLog hvhResume.
	Smalltalk session == session ifFalse: [
		^ self log: 'Checkpoint: resumed from a saved image' ].
	dangling ifNotEmpty: [
		self log: 'Checkpoint: set aside the session handlers of removed classes: '
			, (' ' join: (dangling collect: [ :each | each third handlerId asString ])) ].
	hook := self env: 'HVH_CHECKPOINT_HOOK' ifAbsent: [
		        ^ self log: 'Checkpoint: image saved in ' , (DateAndTime now - start) printString ].
	(LibC uniqueInstance system: hook) = 0
		ifTrue: [
			self log:
				'Checkpoint: image saved and archived in ' , (DateAndTime now - start) printString ]
		ifFalse: [ self log: 'Checkpoint: image saved, but the hook failed: ' , hook ].
	LastCheckpoint := DateAndTime now
]

{ #category : 'checkpoint' }
HvhReplication class >> isDangling: aHandler [
	"A class registered for startup/shutdown that a checkout of the replay has removed."

	^ (aHandler isKindOf: ClassSessionHandler) and: [
		  (Smalltalk globals includesKey:
			   (aHandler instVarNamed: #registeredClassName) asSymbol) not ]
]

{ #category : 'checkpoint' }
HvhReplication class >> removeDanglingSessionHandlers [
	"The replay checks out older commits, which can remove a class that registered itself for
	startup/shutdown. The snapshot then fails on it (KeyNotFound). Such handlers are taken out of
	their list during the snapshot and put back after it, at the same place, so the image goes on
	exactly as without a checkpoint. Answer {list. index. handler} triples, by increasing index."

	| removed |
	removed := OrderedCollection new.
	(SessionManager default instVarNamed: #categories) do: [ :category |
		(category instVarNamed: #priorityLists) valuesDo: [ :handlers |
			handlers doWithIndex: [ :handler :index |
				(self isDangling: handler) ifTrue: [
					removed add: { handlers. index. handler } ] ] ] ].
	removed reverseDo: [ :each | each first removeIndex: each second ].
	^ removed asArray
]

{ #category : 'checkpoint' }
HvhReplication class >> restoreSessionHandlers: triples [

	triples do: [ :each |
		| handlers |
		handlers := each first.
		each second > handlers size
			ifTrue: [ handlers addLast: each third ]
			ifFalse: [ handlers add: each third beforeIndex: each second ] ]
]

{ #category : 'environment' }
HvhReplication class >> env: aName ifAbsent: aBlock [

	^ (OSEnvironment current at: aName ifAbsent: [ nil ])
		  ifNil: aBlock
		  ifNotNil: [ :value | value isEmpty ifTrue: aBlock ifFalse: [ value ] ]
]

{ #category : 'running' }
HvhReplication class >> httpsUrlFor: aString [
	"git@github.com:owner/name.git -> https://github.com/owner/name.git"

	(aString beginsWith: 'git@') ifFalse: [ ^ aString ].
	^ 'https://' , ((aString allButFirst: 4) copyReplaceAll: ':' with: '/')
]

{ #category : 'checkpoint' }
HvhReplication class >> interval [

	^ (self env: 'HVH_CHECKPOINT_MINUTES' ifAbsent: [ '30' ]) asNumber minutes
]

{ #category : 'checkpoint' }
HvhReplication class >> isDue [

	LastCheckpoint ifNil: [ LastCheckpoint := DateAndTime now ].
	^ self isRequested or: [ DateAndTime now - LastCheckpoint >= self interval ]
]

{ #category : 'checkpoint' }
HvhReplication class >> isRequested [

	| file |
	file := (self env: 'HVH_CHECKPOINT_REQUEST' ifAbsent: [ ^ false ]) asFileReference.
	^ file exists and: [ file modificationTime > LastCheckpoint ]
]

{ #category : 'logging' }
HvhReplication class >> log: aString [

	Stdio stdout
		nextPutAll: '[hvh ';
		nextPutAll: DateAndTime now printString;
		nextPutAll: '] ';
		nextPutAll: aString;
		lf;
		flush
]

{ #category : 'checkpoint' }
HvhReplication class >> logFiles [
	"CooCallsiteLog -> its two files, to reopen its streams after a snapshot."

	^ LogFiles ifNil: [ LogFiles := IdentityDictionary new ]
]

{ #category : 'running' }
HvhReplication class >> runConfigurationNamed: aSelector outputDirectory: aDirectory [
	"Same as CooHistoryExperimentRunner class>>#runConfigurationNamed:outputDirectory:, over HTTPS."

	| configuration |
	Iceberg remoteTypeSelector: #httpsUrl.
	configuration := CooHistoryExperimentConfiguration perform: aSelector asSymbol.
	configuration repository: (self httpsUrlFor: configuration repository).
	configuration outputDirectory: aDirectory asFileReference.
	LastCheckpoint := DateAndTime now.
	self log: 'Running ' , aSelector , ' on ' , configuration repository.
	^ [ CooHistoryExperimentRunner new run: configuration ]
		  on: Warning
		  do: [ :warning |
			  Transcript
				  cr;
				  show: 'Warning resumed: ';
				  show: warning messageText asString.
			  warning resume: true ]
]
