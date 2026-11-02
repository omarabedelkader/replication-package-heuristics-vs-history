"
The replication-package additions to the benchmark (see HvhReplication).
"
Class {
	#name : 'BaselineOfHvhReplication',
	#superclass : 'BaselineOf',
	#category : 'BaselineOfHvhReplication',
	#package : 'BaselineOfHvhReplication'
}

{ #category : 'baselines' }
BaselineOfHvhReplication >> baseline: spec [

	<baseline>
	spec for: #common do: [ spec package: 'HVH-Replication' ]
]
