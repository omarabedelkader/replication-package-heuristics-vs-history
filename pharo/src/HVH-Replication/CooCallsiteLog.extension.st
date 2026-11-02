Extension { #name : 'CooCallsiteLog' }

{ #category : '*HVH-Replication' }
CooCallsiteLog >> hvhResume [

	| files |
	callsitesStream ifNil: [ ^ self ].
	files := HvhReplication logFiles at: self ifAbsent: [ ^ self ].
	callsitesStream := files first writeStream setToEnd; yourself.
	ranksStream := files second writeStream setToEnd; yourself
]

{ #category : '*HVH-Replication' }
CooCallsiteLog >> hvhSuspend [
	"File handles do not survive an image restart: the streams are closed around a snapshot."

	callsitesStream ifNotNil: [ :stream | stream close ].
	ranksStream ifNotNil: [ :stream | stream close ]
]

{ #category : '*HVH-Replication' }
CooCallsiteLog >> openOn: aDirectory project: aFilename [
	"Original method, plus remembering the two files (see #hvhResume)."

	| callsitesFile ranksFile |
	aDirectory ensureCreateDirectory.
	callsitesFile := aDirectory / (aFilename , '-callsites.csv').
	ranksFile := aDirectory / (aFilename , '-ranks.csv').
	callsitesFile ensureDelete.
	ranksFile ensureDelete.
	HvhReplication logFiles at: self put: { callsitesFile. ranksFile }.
	callsitesStream := callsitesFile writeStream.
	ranksStream := ranksFile writeStream.
	self
		writeRow: #( kind id commit_index commit package class method target receiver in_history in_own_package in_dependency history_selectors history_classes )
		on: callsitesStream.
	self writeRow: #( kind strategy id prefix rank ms ) on: ranksStream
]
