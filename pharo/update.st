"Reload HVH-Replication from this package (@PKG@ is replaced by bin/run.sh). A fresh image and an
image resumed from a checkpoint thus both run the current version of the additions, even when the
checkpoint was saved by an older one. Loading an unchanged package changes nothing."
[ ((TonelRepository new directory: '@PKG@/pharo/src' asFileReference)
	versionFrom: 'HVH-Replication') load ]
	on: Warning
	do: [ :warning | warning resume: true ].
(Smalltalk globals at: #HvhReplication) log: 'HVH-Replication reloaded from @PKG@/pharo/src'.
