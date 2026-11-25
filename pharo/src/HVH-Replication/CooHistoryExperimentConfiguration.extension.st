Extension { #name : 'CooHistoryExperimentConfiguration' }

{ #category : '*HVH-Replication' }
CooHistoryExperimentConfiguration class >> soil [
	"Project defined by the replication package: ApptiveGrid/Soil, branch main."

	^ self new
		  name: 'Soil';
		  repository: 'https://github.com/ApptiveGrid/Soil.git';
		  numberOfCommits: 200;
		  packageNamePrefix: 'Soil';
		  loader: [
			  Metacello new
				  baseline: 'Soil';
				  repository: 'github://ApptiveGrid/Soil:main/src';
				  onConflict: [ :exception | exception useIncoming ];
				  onUpgrade: [ :exception | exception useIncoming ];
				  load ];
		  outputDirectory: FileLocator workingDirectory / 'History-Bench-Results' / 'Soil';
		  yourself
]


{ #category : '*HVH-Replication' }
CooHistoryExperimentConfiguration class >> molecule [
	"Project defined by the replication package: OpenSmock/Molecule, branch main."

	^ self new
		  name: 'Molecule';
		  repository: 'https://github.com/OpenSmock/Molecule.git';
		  numberOfCommits: 200;
		  packageNamePrefix: 'Molecule';
		  loader: [
			  Metacello new
				  baseline: 'Molecule';
				  repository: 'github://OpenSmock/Molecule:main/src';
				  onConflict: [ :exception | exception useIncoming ];
				  onUpgrade: [ :exception | exception useIncoming ];
				  load ];
		  outputDirectory: FileLocator workingDirectory / 'History-Bench-Results' / 'Molecule';
		  yourself
]


{ #category : '*HVH-Replication' }
CooHistoryExperimentConfiguration class >> pyramid [
	"Project defined by the replication package: OpenSmock/Pyramid, branch main."

	^ self new
		  name: 'Pyramid';
		  repository: 'https://github.com/OpenSmock/Pyramid.git';
		  numberOfCommits: 200;
		  packageNamePrefix: 'Pyramid';
		  loader: [
			  Metacello new
				  baseline: 'Pyramid';
				  repository: 'github://OpenSmock/Pyramid:main/src';
				  onConflict: [ :exception | exception useIncoming ];
				  onUpgrade: [ :exception | exception useIncoming ];
				  load ];
		  outputDirectory: FileLocator workingDirectory / 'History-Bench-Results' / 'Pyramid';
		  yourself
]


{ #category : '*HVH-Replication' }
CooHistoryExperimentConfiguration class >> telescope [
	"Project defined by the replication package: TelescopeSt/Telescope, branch development."

	^ self new
		  name: 'Telescope';
		  repository: 'https://github.com/TelescopeSt/Telescope.git';
		  numberOfCommits: 200;
		  packageNamePrefix: 'Telescope';
		  loader: [
			  Metacello new
				  baseline: 'Telescope';
				  repository: 'github://TelescopeSt/Telescope:development/src';
				  onConflict: [ :exception | exception useIncoming ];
				  onUpgrade: [ :exception | exception useIncoming ];
				  load ];
		  outputDirectory: FileLocator workingDirectory / 'History-Bench-Results' / 'Telescope';
		  yourself
]


{ #category : '*HVH-Replication' }
CooHistoryExperimentConfiguration class >> xmlParser [
	"Project defined by the replication package: pharo-contributions/XML-XMLParser, branch master."

	^ self new
		  name: 'XMLParser';
		  repository: 'https://github.com/pharo-contributions/XML-XMLParser.git';
		  numberOfCommits: 200;
		  packageNamePrefix: 'XML-Parser';
		  loader: [
			  Metacello new
				  baseline: 'XMLParser';
				  repository: 'github://pharo-contributions/XML-XMLParser:master/src';
				  onConflict: [ :exception | exception useIncoming ];
				  onUpgrade: [ :exception | exception useIncoming ];
				  load ];
		  outputDirectory: FileLocator workingDirectory / 'History-Bench-Results' / 'XMLParser';
		  yourself
]


{ #category : '*HVH-Replication' }
CooHistoryExperimentConfiguration class >> materialDesignLite [
	"Project defined by the replication package: DuneSt/MaterialDesignLite, branch development."

	^ self new
		  name: 'MaterialDesignLite';
		  repository: 'https://github.com/DuneSt/MaterialDesignLite.git';
		  numberOfCommits: 200;
		  packageNamePrefix: 'Material-Design-Lite';
		  loader: [
			  Metacello new
				  baseline: 'MaterialDesignLite';
				  repository: 'github://DuneSt/MaterialDesignLite:development/src';
				  onConflict: [ :exception | exception useIncoming ];
				  onUpgrade: [ :exception | exception useIncoming ];
				  load ];
		  outputDirectory: FileLocator workingDirectory / 'History-Bench-Results' / 'MaterialDesignLite';
		  yourself
]


{ #category : '*HVH-Replication' }
CooHistoryExperimentConfiguration class >> cormas [
	"Project defined by the replication package: cormas/cormas, branch master."

	^ self new
		  name: 'Cormas';
		  repository: 'https://github.com/cormas/cormas.git';
		  numberOfCommits: 200;
		  packageNamePrefix: 'Cormas';
		  loader: [
			  Metacello new
				  baseline: 'Cormas';
				  repository: 'github://cormas/cormas:master/src';
				  onConflict: [ :exception | exception useIncoming ];
				  onUpgrade: [ :exception | exception useIncoming ];
				  load ];
		  outputDirectory: FileLocator workingDirectory / 'History-Bench-Results' / 'Cormas';
		  yourself
]


{ #category : '*HVH-Replication' }
CooHistoryExperimentConfiguration class >> muTalk [
	"Project defined by the replication package: pharo-contributions/mutalk, branch master."

	^ self new
		  name: 'MuTalk';
		  repository: 'https://github.com/pharo-contributions/mutalk.git';
		  numberOfCommits: 200;
		  packageNamePrefix: 'MuTalk';
		  loader: [
			  Metacello new
				  baseline: 'MuTalk';
				  repository: 'github://pharo-contributions/mutalk:master/src';
				  onConflict: [ :exception | exception useIncoming ];
				  onUpgrade: [ :exception | exception useIncoming ];
				  load ];
		  outputDirectory: FileLocator workingDirectory / 'History-Bench-Results' / 'MuTalk';
		  yourself
]


{ #category : '*HVH-Replication' }
CooHistoryExperimentConfiguration class >> coypu [
	"Project defined by the replication package: lucretiomsp/Coypu, branch master."

	^ self new
		  name: 'Coypu';
		  repository: 'https://github.com/lucretiomsp/Coypu.git';
		  numberOfCommits: 200;
		  packageNamePrefix: 'Coypu';
		  loader: [
			  Metacello new
				  baseline: 'Coypu';
				  repository: 'github://lucretiomsp/Coypu:master/src';
				  onConflict: [ :exception | exception useIncoming ];
				  onUpgrade: [ :exception | exception useIncoming ];
				  load ];
		  outputDirectory: FileLocator workingDirectory / 'History-Bench-Results' / 'Coypu';
		  yourself
]


{ #category : '*HVH-Replication' }
CooHistoryExperimentConfiguration class >> pharoLanguageServer [
	"Project defined by the replication package: badetitou/Pharo-LanguageServer, branch v6."

	^ self new
		  name: 'PharoLanguageServer';
		  repository: 'https://github.com/badetitou/Pharo-LanguageServer.git';
		  numberOfCommits: 200;
		  packageNamePrefix: 'PharoLanguage';
		  loader: [
			  Metacello new
				  baseline: 'PharoLanguageServer';
				  repository: 'github://badetitou/Pharo-LanguageServer:v6/src';
				  onConflict: [ :exception | exception useIncoming ];
				  onUpgrade: [ :exception | exception useIncoming ];
				  load ];
		  outputDirectory: FileLocator workingDirectory / 'History-Bench-Results' / 'PharoLanguageServer';
		  yourself
]


{ #category : '*HVH-Replication' }
CooHistoryExperimentConfiguration class >> fast [
	"Project defined by the replication package: moosetechnology/FAST, branch v3."

	^ self new
		  name: 'FAST';
		  repository: 'https://github.com/moosetechnology/FAST.git';
		  numberOfCommits: 200;
		  packageNamePrefix: 'FAST-Core';
		  loader: [
			  Metacello new
				  baseline: 'FAST';
				  repository: 'github://moosetechnology/FAST:v3/src';
				  onConflict: [ :exception | exception useIncoming ];
				  onUpgrade: [ :exception | exception useIncoming ];
				  load ];
		  outputDirectory: FileLocator workingDirectory / 'History-Bench-Results' / 'FAST';
		  yourself
]


{ #category : '*HVH-Replication' }
CooHistoryExperimentConfiguration class >> moTion [
	"Project defined by the replication package: moosetechnology/MoTion, branch main."

	^ self new
		  name: 'MoTion';
		  repository: 'https://github.com/moosetechnology/MoTion.git';
		  numberOfCommits: 200;
		  packageNamePrefix: 'MoTion';
		  loader: [
			  Metacello new
				  baseline: 'MoTion';
				  repository: 'github://moosetechnology/MoTion:main/src';
				  onConflict: [ :exception | exception useIncoming ];
				  onUpgrade: [ :exception | exception useIncoming ];
				  load ];
		  outputDirectory: FileLocator workingDirectory / 'History-Bench-Results' / 'MoTion';
		  yourself
]


{ #category : '*HVH-Replication' }
CooHistoryExperimentConfiguration class >> aiGraphAlgorithms [
	"Project defined by the replication package: pharo-ai/graph-algorithms, branch master."

	^ self new
		  name: 'AIGraphAlgorithms';
		  repository: 'https://github.com/pharo-ai/graph-algorithms.git';
		  numberOfCommits: 200;
		  packageNamePrefix: 'AI-Algorithms';
		  loader: [
			  Metacello new
				  baseline: 'AIGraphAlgorithms';
				  repository: 'github://pharo-ai/graph-algorithms:master/src';
				  onConflict: [ :exception | exception useIncoming ];
				  onUpgrade: [ :exception | exception useIncoming ];
				  load ];
		  outputDirectory: FileLocator workingDirectory / 'History-Bench-Results' / 'AIGraphAlgorithms';
		  yourself
]


{ #category : '*HVH-Replication' }
CooHistoryExperimentConfiguration class >> petitParser2 [
	"Project defined by the replication package: kursjan/petitparser2, branch master."

	^ self new
		  name: 'PetitParser2';
		  repository: 'https://github.com/kursjan/petitparser2.git';
		  numberOfCommits: 200;
		  packageNamePrefix: 'PetitParser2';
		  loader: [
			  Metacello new
				  baseline: 'PetitParser2';
				  repository: 'github://kursjan/petitparser2:master';
				  onConflict: [ :exception | exception useIncoming ];
				  onUpgrade: [ :exception | exception useIncoming ];
				  load ];
		  outputDirectory: FileLocator workingDirectory / 'History-Bench-Results' / 'PetitParser2';
		  yourself
]


{ #category : '*HVH-Replication' }
CooHistoryExperimentConfiguration class >> taskIt [
	"Project defined by the replication package: pharo-contributions/taskit, branch master."

	^ self new
		  name: 'TaskIt';
		  repository: 'https://github.com/pharo-contributions/taskit.git';
		  numberOfCommits: 200;
		  packageNamePrefix: 'TaskIt';
		  loader: [
			  Metacello new
				  baseline: 'TaskIt';
				  repository: 'github://pharo-contributions/taskit:master';
				  onConflict: [ :exception | exception useIncoming ];
				  onUpgrade: [ :exception | exception useIncoming ];
				  load ];
		  outputDirectory: FileLocator workingDirectory / 'History-Bench-Results' / 'TaskIt';
		  yourself
]


{ #category : '*HVH-Replication' }
CooHistoryExperimentConfiguration class >> codeParadise [
	"Project defined by the replication package: ErikOnBike/CodeParadise, branch master."

	^ self new
		  name: 'CodeParadise';
		  repository: 'https://github.com/ErikOnBike/CodeParadise.git';
		  numberOfCommits: 200;
		  packageNamePrefix: 'CodeParadise';
		  loader: [
			  Metacello new
				  baseline: 'CodeParadise';
				  repository: 'github://ErikOnBike/CodeParadise:master/repository';
				  onConflict: [ :exception | exception useIncoming ];
				  onUpgrade: [ :exception | exception useIncoming ];
				  load ];
		  outputDirectory: FileLocator workingDirectory / 'History-Bench-Results' / 'CodeParadise';
		  yourself
]


{ #category : '*HVH-Replication' }
CooHistoryExperimentConfiguration class >> p3 [
	"Project defined by the replication package: svenvc/P3, branch master."

	^ self new
		  name: 'P3';
		  repository: 'https://github.com/svenvc/P3.git';
		  numberOfCommits: 200;
		  packageNamePrefix: 'P3';
		  loader: [
			  Metacello new
				  baseline: 'P3';
				  repository: 'github://svenvc/P3:master';
				  onConflict: [ :exception | exception useIncoming ];
				  onUpgrade: [ :exception | exception useIncoming ];
				  load ];
		  outputDirectory: FileLocator workingDirectory / 'History-Bench-Results' / 'P3';
		  yourself
]


{ #category : '*HVH-Replication' }
CooHistoryExperimentConfiguration class >> openAPI [
	"Project defined by the replication package: ApptiveGrid/OpenAPI, branch master."

	^ self new
		  name: 'OpenAPI';
		  repository: 'https://github.com/ApptiveGrid/OpenAPI.git';
		  numberOfCommits: 200;
		  packageNamePrefix: 'OpenAPI';
		  loader: [
			  Metacello new
				  baseline: 'OpenAPI';
				  repository: 'github://ApptiveGrid/OpenAPI:master/source';
				  onConflict: [ :exception | exception useIncoming ];
				  onUpgrade: [ :exception | exception useIncoming ];
				  load ];
		  outputDirectory: FileLocator workingDirectory / 'History-Bench-Results' / 'OpenAPI';
		  yourself
]


{ #category : '*HVH-Replication' }
CooHistoryExperimentConfiguration class >> mongoTalk [
	"Project defined by the replication package: pharo-nosql/mongotalk, branch master."

	^ self new
		  name: 'MongoTalk';
		  repository: 'https://github.com/pharo-nosql/mongotalk.git';
		  numberOfCommits: 200;
		  packageNamePrefix: 'Mongo';
		  loader: [
			  Metacello new
				  baseline: 'MongoTalk';
				  repository: 'github://pharo-nosql/mongotalk:master/mc';
				  onConflict: [ :exception | exception useIncoming ];
				  onUpgrade: [ :exception | exception useIncoming ];
				  load ];
		  outputDirectory: FileLocator workingDirectory / 'History-Bench-Results' / 'MongoTalk';
		  yourself
]


{ #category : '*HVH-Replication' }
CooHistoryExperimentConfiguration class >> grease [
	"Project defined by the replication package: SeasideSt/Grease, branch master."

	^ self new
		  name: 'Grease';
		  repository: 'https://github.com/SeasideSt/Grease.git';
		  numberOfCommits: 200;
		  packageNamePrefix: 'Grease';
		  loader: [
			  Metacello new
				  baseline: 'Grease';
				  repository: 'github://SeasideSt/Grease:master/repository';
				  onConflict: [ :exception | exception useIncoming ];
				  onUpgrade: [ :exception | exception useIncoming ];
				  load ];
		  outputDirectory: FileLocator workingDirectory / 'History-Bench-Results' / 'Grease';
		  yourself
]


{ #category : '*HVH-Replication' }
CooHistoryExperimentConfiguration class >> parasol [
	"Project defined by the replication package: SeasideSt/Parasol, branch master."

	^ self new
		  name: 'Parasol';
		  repository: 'https://github.com/SeasideSt/Parasol.git';
		  numberOfCommits: 200;
		  packageNamePrefix: 'Parasol';
		  loader: [
			  Metacello new
				  baseline: 'Parasol';
				  repository: 'github://SeasideSt/Parasol:master/repository';
				  onConflict: [ :exception | exception useIncoming ];
				  onUpgrade: [ :exception | exception useIncoming ];
				  load ];
		  outputDirectory: FileLocator workingDirectory / 'History-Bench-Results' / 'Parasol';
		  yourself
]


{ #category : '*HVH-Replication' }
CooHistoryExperimentConfiguration class >> neoCSV [
	"Project defined by the replication package: svenvc/NeoCSV, branch master."

	^ self new
		  name: 'NeoCSV';
		  repository: 'https://github.com/svenvc/NeoCSV.git';
		  numberOfCommits: 200;
		  packageNamePrefix: 'Neo-CSV';
		  loader: [
			  Metacello new
				  baseline: 'NeoCSV';
				  repository: 'github://svenvc/NeoCSV:master/repository';
				  onConflict: [ :exception | exception useIncoming ];
				  onUpgrade: [ :exception | exception useIncoming ];
				  load ];
		  outputDirectory: FileLocator workingDirectory / 'History-Bench-Results' / 'NeoCSV';
		  yourself
]


{ #category : '*HVH-Replication' }
CooHistoryExperimentConfiguration class >> neoJSON [
	"Project defined by the replication package: svenvc/NeoJSON, branch master."

	^ self new
		  name: 'NeoJSON';
		  repository: 'https://github.com/svenvc/NeoJSON.git';
		  numberOfCommits: 200;
		  packageNamePrefix: 'Neo-JSON';
		  loader: [
			  Metacello new
				  baseline: 'NeoJSON';
				  repository: 'github://svenvc/NeoJSON:master/repository';
				  onConflict: [ :exception | exception useIncoming ];
				  onUpgrade: [ :exception | exception useIncoming ];
				  load ];
		  outputDirectory: FileLocator workingDirectory / 'History-Bench-Results' / 'NeoJSON';
		  yourself
]


{ #category : '*HVH-Replication' }
CooHistoryExperimentConfiguration class >> reStore [
	"Project defined by the replication package: rko281/ReStoreForPharo, branch main."

	^ self new
		  name: 'ReStore';
		  repository: 'https://github.com/rko281/ReStoreForPharo.git';
		  numberOfCommits: 200;
		  packageNamePrefix: 'SSW ReStore';
		  loader: [
			  Metacello new
				  baseline: 'ReStore';
				  repository: 'github://rko281/ReStoreForPharo:main';
				  onConflict: [ :exception | exception useIncoming ];
				  onUpgrade: [ :exception | exception useIncoming ];
				  load ];
		  outputDirectory: FileLocator workingDirectory / 'History-Bench-Results' / 'ReStore';
		  yourself
]


{ #category : '*HVH-Replication' }
CooHistoryExperimentConfiguration class >> phausto [
	"Project defined by the replication package: lucretiomsp/phausto, branch main."

	^ self new
		  name: 'Phausto';
		  repository: 'https://github.com/lucretiomsp/phausto.git';
		  numberOfCommits: 200;
		  packageNamePrefix: 'Phausto';
		  loader: [
			  Metacello new
				  baseline: 'Phausto';
				  repository: 'github://lucretiomsp/phausto:main';
				  onConflict: [ :exception | exception useIncoming ];
				  onUpgrade: [ :exception | exception useIncoming ];
				  load ];
		  outputDirectory: FileLocator workingDirectory / 'History-Bench-Results' / 'Phausto';
		  yourself
]


{ #category : '*HVH-Replication' }
CooHistoryExperimentConfiguration class >> exercism [
	"Project defined by the replication package: exercism/pharo-smalltalk, branch main."

	^ self new
		  name: 'Exercism';
		  repository: 'https://github.com/exercism/pharo-smalltalk.git';
		  numberOfCommits: 200;
		  packageNamePrefix: 'Exercism';
		  loader: [
			  Metacello new
				  baseline: 'Exercism';
				  repository: 'github://exercism/pharo-smalltalk:main/dev/src';
				  onConflict: [ :exception | exception useIncoming ];
				  onUpgrade: [ :exception | exception useIncoming ];
				  load ];
		  outputDirectory: FileLocator workingDirectory / 'History-Bench-Results' / 'Exercism';
		  yourself
]


{ #category : '*HVH-Replication' }
CooHistoryExperimentConfiguration class >> smacc [
	"Project defined by the replication package: j-brant/SmaCC, branch master."

	^ self new
		  name: 'SmaCC';
		  repository: 'https://github.com/j-brant/SmaCC.git';
		  numberOfCommits: 200;
		  packageNamePrefix: 'SmaCC';
		  loader: [
			  Metacello new
				  baseline: 'SmaCC';
				  repository: 'github://j-brant/SmaCC:master/src';
				  onConflict: [ :exception | exception useIncoming ];
				  onUpgrade: [ :exception | exception useIncoming ];
				  load ];
		  outputDirectory: FileLocator workingDirectory / 'History-Bench-Results' / 'SmaCC';
		  yourself
]


{ #category : '*HVH-Replication' }
CooHistoryExperimentConfiguration class >> sqlite3 [
	"Project defined by the replication package: pharo-rdbms/Pharo-SQLite3, branch master."

	^ self new
		  name: 'SQLite3';
		  repository: 'https://github.com/pharo-rdbms/Pharo-SQLite3.git';
		  numberOfCommits: 200;
		  packageNamePrefix: 'SQLite3';
		  loader: [
			  Metacello new
				  baseline: 'SQLite3';
				  repository: 'github://pharo-rdbms/Pharo-SQLite3:master/src';
				  onConflict: [ :exception | exception useIncoming ];
				  onUpgrade: [ :exception | exception useIncoming ];
				  load ];
		  outputDirectory: FileLocator workingDirectory / 'History-Bench-Results' / 'SQLite3';
		  yourself
]


{ #category : '*HVH-Replication' }
CooHistoryExperimentConfiguration class >> territorial [
	"Project defined by the replication package: hernanmd/Territorial, branch master."

	^ self new
		  name: 'Territorial';
		  repository: 'https://github.com/hernanmd/Territorial.git';
		  numberOfCommits: 200;
		  packageNamePrefix: 'Territorial';
		  loader: [
			  Metacello new
				  baseline: 'Territorial';
				  repository: 'github://hernanmd/Territorial:master/repository';
				  onConflict: [ :exception | exception useIncoming ];
				  onUpgrade: [ :exception | exception useIncoming ];
				  load ];
		  outputDirectory: FileLocator workingDirectory / 'History-Bench-Results' / 'Territorial';
		  yourself
]


{ #category : '*HVH-Replication' }
CooHistoryExperimentConfiguration class >> bioSmalltalk [
	"Project defined by the replication package: hernanmd/BioSmalltalk, branch master."

	^ self new
		  name: 'BioSmalltalk';
		  repository: 'https://github.com/hernanmd/BioSmalltalk.git';
		  numberOfCommits: 200;
		  packageNamePrefix: 'BioSmalltalk';
		  loader: [
			  Metacello new
				  baseline: 'BioSmalltalk';
				  repository: 'github://hernanmd/BioSmalltalk:master/repository';
				  onConflict: [ :exception | exception useIncoming ];
				  onUpgrade: [ :exception | exception useIncoming ];
				  load ];
		  outputDirectory: FileLocator workingDirectory / 'History-Bench-Results' / 'BioSmalltalk';
		  yourself
]


{ #category : '*HVH-Replication' }
CooHistoryExperimentConfiguration class >> egg [
	"Project defined by the replication package: powerlang/egg, branch main."

	^ self new
		  name: 'Egg';
		  repository: 'https://github.com/powerlang/egg.git';
		  numberOfCommits: 200;
		  packageNamePrefix: 'Powerlang';
		  loader: [
			  Metacello new
				  baseline: 'Powerlang';
				  repository: 'github://powerlang/egg:main/runtime/pharo';
				  onConflict: [ :exception | exception useIncoming ];
				  onUpgrade: [ :exception | exception useIncoming ];
				  load ];
		  outputDirectory: FileLocator workingDirectory / 'History-Bench-Results' / 'Egg';
		  yourself
]


{ #category : '*HVH-Replication' }
CooHistoryExperimentConfiguration class >> viennaTalk [
	"Project defined by the replication package: tomooda/ViennaTalk, branch main."

	^ self new
		  name: 'ViennaTalk';
		  repository: 'https://github.com/tomooda/ViennaTalk.git';
		  numberOfCommits: 200;
		  packageNamePrefix: 'ViennaTalk';
		  loader: [
			  Metacello new
				  baseline: 'ViennaTalk';
				  repository: 'github://tomooda/ViennaTalk:main/repository';
				  onConflict: [ :exception | exception useIncoming ];
				  onUpgrade: [ :exception | exception useIncoming ];
				  load ];
		  outputDirectory: FileLocator workingDirectory / 'History-Bench-Results' / 'ViennaTalk';
		  yourself
]


{ #category : '*HVH-Replication' }
CooHistoryExperimentConfiguration class >> pakbot [
	"Project defined by the replication package: pharo-pkg/pakbot, branch master."

	^ self new
		  name: 'Pakbot';
		  repository: 'https://github.com/pharo-pkg/pakbot.git';
		  numberOfCommits: 200;
		  packageNamePrefix: 'Pakbot';
		  loader: [
			  Metacello new
				  baseline: 'Pakbot';
				  repository: 'github://pharo-pkg/pakbot:master/repository';
				  onConflict: [ :exception | exception useIncoming ];
				  onUpgrade: [ :exception | exception useIncoming ];
				  load ];
		  outputDirectory: FileLocator workingDirectory / 'History-Bench-Results' / 'Pakbot';
		  yourself
]


{ #category : '*HVH-Replication' }
CooHistoryExperimentConfiguration class >> geoView [
	"Project defined by the replication package: ThalesGroup/GeoView, branch main."

	^ self new
		  name: 'GeoView';
		  repository: 'https://github.com/ThalesGroup/GeoView.git';
		  numberOfCommits: 200;
		  packageNamePrefix: 'GeoView';
		  loader: [
			  Metacello new
				  baseline: 'GeoView';
				  repository: 'github://ThalesGroup/GeoView:main/src';
				  onConflict: [ :exception | exception useIncoming ];
				  onUpgrade: [ :exception | exception useIncoming ];
				  load ];
		  outputDirectory: FileLocator workingDirectory / 'History-Bench-Results' / 'GeoView';
		  yourself
]


{ #category : '*HVH-Replication' }
CooHistoryExperimentConfiguration class >> reMobidyc [
	"Project defined by the replication package: ReMobidyc/ReMobidyc, branch main."

	^ self new
		  name: 'ReMobidyc';
		  repository: 'https://github.com/ReMobidyc/ReMobidyc.git';
		  numberOfCommits: 200;
		  packageNamePrefix: 'ReMobidyc';
		  loader: [
			  Metacello new
				  baseline: 'ReMobidyc';
				  repository: 'github://ReMobidyc/ReMobidyc:main/src';
				  onConflict: [ :exception | exception useIncoming ];
				  onUpgrade: [ :exception | exception useIncoming ];
				  load ];
		  outputDirectory: FileLocator workingDirectory / 'History-Bench-Results' / 'ReMobidyc';
		  yourself
]


{ #category : '*HVH-Replication' }
CooHistoryExperimentConfiguration class >> agenticBrowser [
	"Project defined by the replication package: mumez/pharo-agentic-browser, branch develop."

	^ self new
		  name: 'AgenticBrowser';
		  repository: 'https://github.com/mumez/pharo-agentic-browser.git';
		  numberOfCommits: 200;
		  packageNamePrefix: 'AgenticBrowser';
		  loader: [
			  Metacello new
				  baseline: 'AgenticBrowser';
				  repository: 'github://mumez/pharo-agentic-browser:develop/src';
				  onConflict: [ :exception | exception useIncoming ];
				  onUpgrade: [ :exception | exception useIncoming ];
				  load ];
		  outputDirectory: FileLocator workingDirectory / 'History-Bench-Results' / 'AgenticBrowser';
		  yourself
]


{ #category : '*HVH-Replication' }
CooHistoryExperimentConfiguration class >> mcp [
	"Project defined by the replication package: Evref-BL/MCP, branch main."

	^ self new
		  name: 'MCP';
		  repository: 'https://github.com/Evref-BL/MCP.git';
		  numberOfCommits: 200;
		  packageNamePrefix: 'MCP';
		  loader: [
			  Metacello new
				  baseline: 'MCP';
				  repository: 'github://Evref-BL/MCP:main/src';
				  onConflict: [ :exception | exception useIncoming ];
				  onUpgrade: [ :exception | exception useIncoming ];
				  load ];
		  outputDirectory: FileLocator workingDirectory / 'History-Bench-Results' / 'MCP';
		  yourself
]


{ #category : '*HVH-Replication' }
CooHistoryExperimentConfiguration class >> rediStick [
	"Project defined by the replication package: mumez/RediStick, branch master."

	^ self new
		  name: 'RediStick';
		  repository: 'https://github.com/mumez/RediStick.git';
		  numberOfCommits: 200;
		  packageNamePrefix: 'RediStick';
		  loader: [
			  Metacello new
				  baseline: 'RediStick';
				  repository: 'github://mumez/RediStick:master/src';
				  onConflict: [ :exception | exception useIncoming ];
				  onUpgrade: [ :exception | exception useIncoming ];
				  load ];
		  outputDirectory: FileLocator workingDirectory / 'History-Bench-Results' / 'RediStick';
		  yourself
]


{ #category : '*HVH-Replication' }
CooHistoryExperimentConfiguration class >> rita [
	"Project defined by the replication package: pharo-vcs/Rita, branch Pharo15."

	^ self new
		  name: 'Rita';
		  repository: 'https://github.com/pharo-vcs/Rita.git';
		  numberOfCommits: 200;
		  packageNamePrefix: 'Rita';
		  loader: [
			  Metacello new
				  baseline: 'Rita';
				  repository: 'github://pharo-vcs/Rita:Pharo15/src';
				  onConflict: [ :exception | exception useIncoming ];
				  onUpgrade: [ :exception | exception useIncoming ];
				  load ];
		  outputDirectory: FileLocator workingDirectory / 'History-Bench-Results' / 'Rita';
		  yourself
]


{ #category : '*HVH-Replication' }
CooHistoryExperimentConfiguration class >> openTelemetry [
	"Project defined by the replication package: Gabriel-Darbord/opentelemetry-pharo, branch main."

	^ self new
		  name: 'OpenTelemetry';
		  repository: 'https://github.com/Gabriel-Darbord/opentelemetry-pharo.git';
		  numberOfCommits: 200;
		  packageNamePrefix: 'OpenTelemetry';
		  loader: [
			  Metacello new
				  baseline: 'OpenTelemetry';
				  repository: 'github://Gabriel-Darbord/opentelemetry-pharo:main/src';
				  onConflict: [ :exception | exception useIncoming ];
				  onUpgrade: [ :exception | exception useIncoming ];
				  load ];
		  outputDirectory: FileLocator workingDirectory / 'History-Bench-Results' / 'OpenTelemetry';
		  yourself
]


{ #category : '*HVH-Replication' }
CooHistoryExperimentConfiguration class >> specToplo [
	"Project defined by the replication package: pharo-graphics/Spec-Toplo, branch dev."

	^ self new
		  name: 'SpecToplo';
		  repository: 'https://github.com/pharo-graphics/Spec-Toplo.git';
		  numberOfCommits: 200;
		  packageNamePrefix: 'SpecToplo';
		  loader: [
			  Metacello new
				  baseline: 'SpecToplo';
				  repository: 'github://pharo-graphics/Spec-Toplo:dev/src';
				  onConflict: [ :exception | exception useIncoming ];
				  onUpgrade: [ :exception | exception useIncoming ];
				  load ];
		  outputDirectory: FileLocator workingDirectory / 'History-Bench-Results' / 'SpecToplo';
		  yourself
]


{ #category : '*HVH-Replication' }
CooHistoryExperimentConfiguration class >> classNameAnalyser [
	"Project defined by the replication package: moosetechnology/ClassNameAnalyser, branch master."

	^ self new
		  name: 'ClassNameAnalyser';
		  repository: 'https://github.com/moosetechnology/ClassNameAnalyser.git';
		  numberOfCommits: 200;
		  packageNamePrefix: 'ClassNameAnalyser';
		  loader: [
			  Metacello new
				  baseline: 'ClassNameAnalyser';
				  repository: 'github://moosetechnology/ClassNameAnalyser:master/src';
				  onConflict: [ :exception | exception useIncoming ];
				  onUpgrade: [ :exception | exception useIncoming ];
				  load ];
		  outputDirectory: FileLocator workingDirectory / 'History-Bench-Results' / 'ClassNameAnalyser';
		  yourself
]


{ #category : '*HVH-Replication' }
CooHistoryExperimentConfiguration class >> rewriteToolsSet [
	"Project defined by the replication package: jordanmontt/RewriteToolsSet, branch master."

	^ self new
		  name: 'RewriteToolsSet';
		  repository: 'https://github.com/jordanmontt/RewriteToolsSet.git';
		  numberOfCommits: 200;
		  packageNamePrefix: 'RewriteToolsSet';
		  loader: [
			  Metacello new
				  baseline: 'RewriteToolsSet';
				  repository: 'github://jordanmontt/RewriteToolsSet:master/src';
				  onConflict: [ :exception | exception useIncoming ];
				  onUpgrade: [ :exception | exception useIncoming ];
				  load ];
		  outputDirectory: FileLocator workingDirectory / 'History-Bench-Results' / 'RewriteToolsSet';
		  yourself
]


{ #category : '*HVH-Replication' }
CooHistoryExperimentConfiguration class >> asn1 [
	"Project defined by the replication package: noha/ASN.1, branch master."

	^ self new
		  name: 'ASN1';
		  repository: 'https://github.com/noha/ASN.1.git';
		  numberOfCommits: 200;
		  packageNamePrefix: 'ASN1';
		  loader: [
			  Metacello new
				  baseline: 'ASN1';
				  repository: 'github://noha/ASN.1:master';
				  onConflict: [ :exception | exception useIncoming ];
				  onUpgrade: [ :exception | exception useIncoming ];
				  load ];
		  outputDirectory: FileLocator workingDirectory / 'History-Bench-Results' / 'ASN1';
		  yourself
]


{ #category : '*HVH-Replication' }
CooHistoryExperimentConfiguration class >> webside [
	"Project defined by the replication package: guillermoamaral/Pharo-Webside, branch main."

	^ self new
		  name: 'Webside';
		  repository: 'https://github.com/guillermoamaral/Pharo-Webside.git';
		  numberOfCommits: 200;
		  packageNamePrefix: 'Webside';
		  loader: [
			  Metacello new
				  baseline: 'Webside';
				  repository: 'github://guillermoamaral/Pharo-Webside:main';
				  onConflict: [ :exception | exception useIncoming ];
				  onUpgrade: [ :exception | exception useIncoming ];
				  load ];
		  outputDirectory: FileLocator workingDirectory / 'History-Bench-Results' / 'Webside';
		  yourself
]


{ #category : '*HVH-Replication' }
CooHistoryExperimentConfiguration class >> openSmock [
	"Project defined by the replication package: OpenSmock/OpenSmock, branch main."

	^ self new
		  name: 'OpenSmock';
		  repository: 'https://github.com/OpenSmock/OpenSmock.git';
		  numberOfCommits: 200;
		  packageNamePrefix: 'OpenSmock';
		  loader: [
			  Metacello new
				  baseline: 'OpenSmock';
				  repository: 'github://OpenSmock/OpenSmock:main/src';
				  onConflict: [ :exception | exception useIncoming ];
				  onUpgrade: [ :exception | exception useIncoming ];
				  load ];
		  outputDirectory: FileLocator workingDirectory / 'History-Bench-Results' / 'OpenSmock';
		  yourself
]


{ #category : '*HVH-Replication' }
CooHistoryExperimentConfiguration class >> microKanren [
	"Project defined by the replication package: massimo-nocentini/microkanrenst, branch master."

	^ self new
		  name: 'MicroKanren';
		  repository: 'https://github.com/massimo-nocentini/microkanrenst.git';
		  numberOfCommits: 200;
		  packageNamePrefix: 'MicroKanren';
		  loader: [
			  Metacello new
				  baseline: 'MicroKanren';
				  repository: 'github://massimo-nocentini/microkanrenst:master';
				  onConflict: [ :exception | exception useIncoming ];
				  onUpgrade: [ :exception | exception useIncoming ];
				  load ];
		  outputDirectory: FileLocator workingDirectory / 'History-Bench-Results' / 'MicroKanren';
		  yourself
]


{ #category : '*HVH-Replication' }
CooHistoryExperimentConfiguration class >> pharoCIG [
	"Project defined by the replication package: pharo-cig/pharo-cig, branch main."

	^ self new
		  name: 'PharoCIG';
		  repository: 'https://github.com/pharo-cig/pharo-cig.git';
		  numberOfCommits: 200;
		  packageNamePrefix: 'CIG';
		  loader: [
			  Metacello new
				  baseline: 'CIG';
				  repository: 'github://pharo-cig/pharo-cig:main/src';
				  onConflict: [ :exception | exception useIncoming ];
				  onUpgrade: [ :exception | exception useIncoming ];
				  load ];
		  outputDirectory: FileLocator workingDirectory / 'History-Bench-Results' / 'PharoCIG';
		  yourself
]


{ #category : '*HVH-Replication' }
CooHistoryExperimentConfiguration class >> snapDump [
	"Project defined by the replication package: ApptiveGrid/SnapDump, branch master."

	^ self new
		  name: 'SnapDump';
		  repository: 'https://github.com/ApptiveGrid/SnapDump.git';
		  numberOfCommits: 200;
		  packageNamePrefix: 'SnapDump';
		  loader: [
			  Metacello new
				  baseline: 'SnapDump';
				  repository: 'github://ApptiveGrid/SnapDump:master/source';
				  onConflict: [ :exception | exception useIncoming ];
				  onUpgrade: [ :exception | exception useIncoming ];
				  load ];
		  outputDirectory: FileLocator workingDirectory / 'History-Bench-Results' / 'SnapDump';
		  yourself
]


{ #category : '*HVH-Replication' }
CooHistoryExperimentConfiguration class >> gitMiner [
	"Project defined by the replication package: USIREVEAL/gitminer, branch main."

	^ self new
		  name: 'GitMiner';
		  repository: 'https://github.com/USIREVEAL/gitminer.git';
		  numberOfCommits: 200;
		  packageNamePrefix: 'GitMiner';
		  loader: [
			  Metacello new
				  baseline: 'GitMiner';
				  repository: 'github://USIREVEAL/gitminer:main/src';
				  onConflict: [ :exception | exception useIncoming ];
				  onUpgrade: [ :exception | exception useIncoming ];
				  load ];
		  outputDirectory: FileLocator workingDirectory / 'History-Bench-Results' / 'GitMiner';
		  yourself
]


{ #category : '*HVH-Replication' }
CooHistoryExperimentConfiguration class >> seasideBootstrap5 [
	"Project defined by the replication package: astares/Seaside-Bootstrap5, branch master."

	^ self new
		  name: 'SeasideBootstrap5';
		  repository: 'https://github.com/astares/Seaside-Bootstrap5.git';
		  numberOfCommits: 200;
		  packageNamePrefix: 'Bootstrap5';
		  loader: [
			  Metacello new
				  baseline: 'Bootstrap5';
				  repository: 'github://astares/Seaside-Bootstrap5:master/src';
				  onConflict: [ :exception | exception useIncoming ];
				  onUpgrade: [ :exception | exception useIncoming ];
				  load ];
		  outputDirectory: FileLocator workingDirectory / 'History-Bench-Results' / 'SeasideBootstrap5';
		  yourself
]


{ #category : '*HVH-Replication' }
CooHistoryExperimentConfiguration class >> jsonSchema [
	"Project defined by the replication package: ApptiveGrid/JSONSchema, branch master."

	^ self new
		  name: 'JSONSchema';
		  repository: 'https://github.com/ApptiveGrid/JSONSchema.git';
		  numberOfCommits: 200;
		  packageNamePrefix: 'JSONSchema';
		  loader: [
			  Metacello new
				  baseline: 'JSONSchema';
				  repository: 'github://ApptiveGrid/JSONSchema:master/source';
				  onConflict: [ :exception | exception useIncoming ];
				  onUpgrade: [ :exception | exception useIncoming ];
				  load ];
		  outputDirectory: FileLocator workingDirectory / 'History-Bench-Results' / 'JSONSchema';
		  yourself
]


{ #category : '*HVH-Replication' }
CooHistoryExperimentConfiguration class >> chipDesigner [
	"Project defined by the replication package: pavel-krivanek/PharoChipDesigner, branch master."

	^ self new
		  name: 'ChipDesigner';
		  repository: 'https://github.com/pavel-krivanek/PharoChipDesigner.git';
		  numberOfCommits: 200;
		  packageNamePrefix: 'ChipDesigner';
		  loader: [
			  Metacello new
				  baseline: 'ChipDesigner';
				  repository: 'github://pavel-krivanek/PharoChipDesigner:master/src';
				  onConflict: [ :exception | exception useIncoming ];
				  onUpgrade: [ :exception | exception useIncoming ];
				  load ];
		  outputDirectory: FileLocator workingDirectory / 'History-Bench-Results' / 'ChipDesigner';
		  yourself
]


{ #category : '*HVH-Replication' }
CooHistoryExperimentConfiguration class >> beacon [
	"Project defined by the replication package: pharo-project/pharo-beacon, branch master."

	^ self new
		  name: 'Beacon';
		  repository: 'https://github.com/pharo-project/pharo-beacon.git';
		  numberOfCommits: 200;
		  packageNamePrefix: 'Beacon';
		  loader: [
			  Metacello new
				  baseline: 'Beacon';
				  repository: 'github://pharo-project/pharo-beacon:master/src';
				  onConflict: [ :exception | exception useIncoming ];
				  onUpgrade: [ :exception | exception useIncoming ];
				  load ];
		  outputDirectory: FileLocator workingDirectory / 'History-Bench-Results' / 'Beacon';
		  yourself
]


{ #category : '*HVH-Replication' }
CooHistoryExperimentConfiguration class >> citezen [
	"Project defined by the replication package: Ducasse/Citezen, branch master."

	^ self new
		  name: 'Citezen';
		  repository: 'https://github.com/Ducasse/Citezen.git';
		  numberOfCommits: 200;
		  packageNamePrefix: 'Citezen';
		  loader: [
			  Metacello new
				  baseline: 'Citezen';
				  repository: 'github://Ducasse/Citezen:master/src';
				  onConflict: [ :exception | exception useIncoming ];
				  onUpgrade: [ :exception | exception useIncoming ];
				  load ];
		  outputDirectory: FileLocator workingDirectory / 'History-Bench-Results' / 'Citezen';
		  yourself
]


{ #category : '*HVH-Replication' }
CooHistoryExperimentConfiguration class >> awsSDK [
	"Project defined by the replication package: newapplesho/aws-sdk-smalltalk, branch main."

	^ self new
		  name: 'AWSSDK';
		  repository: 'https://github.com/newapplesho/aws-sdk-smalltalk.git';
		  numberOfCommits: 200;
		  packageNamePrefix: 'AWS';
		  loader: [
			  Metacello new
				  baseline: 'AWS';
				  repository: 'github://newapplesho/aws-sdk-smalltalk:main/src';
				  onConflict: [ :exception | exception useIncoming ];
				  onUpgrade: [ :exception | exception useIncoming ];
				  load ];
		  outputDirectory: FileLocator workingDirectory / 'History-Bench-Results' / 'AWSSDK';
		  yourself
]


{ #category : '*HVH-Replication' }
CooHistoryExperimentConfiguration class >> pTerm [
	"Project defined by the replication package: lxsang/PTerm, branch master."

	^ self new
		  name: 'PTerm';
		  repository: 'https://github.com/lxsang/PTerm.git';
		  numberOfCommits: 200;
		  packageNamePrefix: 'PTerm';
		  loader: [
			  Metacello new
				  baseline: 'PTerm';
				  repository: 'github://lxsang/PTerm:master';
				  onConflict: [ :exception | exception useIncoming ];
				  onUpgrade: [ :exception | exception useIncoming ];
				  load ];
		  outputDirectory: FileLocator workingDirectory / 'History-Bench-Results' / 'PTerm';
		  yourself
]


{ #category : '*HVH-Replication' }
CooHistoryExperimentConfiguration class >> soup [
	"Project defined by the replication package: pharo-contributions/Soup, branch master."

	^ self new
		  name: 'Soup';
		  repository: 'https://github.com/pharo-contributions/Soup.git';
		  numberOfCommits: 200;
		  packageNamePrefix: 'Soup';
		  loader: [
			  Metacello new
				  baseline: 'Soup';
				  repository: 'github://pharo-contributions/Soup:master/src';
				  onConflict: [ :exception | exception useIncoming ];
				  onUpgrade: [ :exception | exception useIncoming ];
				  load ];
		  outputDirectory: FileLocator workingDirectory / 'History-Bench-Results' / 'Soup';
		  yourself
]


{ #category : '*HVH-Replication' }
CooHistoryExperimentConfiguration class >> blocTutorials [
	"Project defined by the replication package: pharo-graphics/Tutorials, branch master."

	^ self new
		  name: 'BlocTutorials';
		  repository: 'https://github.com/pharo-graphics/Tutorials.git';
		  numberOfCommits: 200;
		  packageNamePrefix: 'BlocTutorials';
		  loader: [
			  Metacello new
				  baseline: 'BlocTutorials';
				  repository: 'github://pharo-graphics/Tutorials:master/src';
				  onConflict: [ :exception | exception useIncoming ];
				  onUpgrade: [ :exception | exception useIncoming ];
				  load ];
		  outputDirectory: FileLocator workingDirectory / 'History-Bench-Results' / 'BlocTutorials';
		  yourself
]


{ #category : '*HVH-Replication' }
CooHistoryExperimentConfiguration class >> seamless [
	"Project defined by the replication package: pharo-ide/Seamless, branch master."

	^ self new
		  name: 'Seamless';
		  repository: 'https://github.com/pharo-ide/Seamless.git';
		  numberOfCommits: 200;
		  packageNamePrefix: 'Seamless';
		  loader: [
			  Metacello new
				  baseline: 'Seamless';
				  repository: 'github://pharo-ide/Seamless:master';
				  onConflict: [ :exception | exception useIncoming ];
				  onUpgrade: [ :exception | exception useIncoming ];
				  load ];
		  outputDirectory: FileLocator workingDirectory / 'History-Bench-Results' / 'Seamless';
		  yourself
]


{ #category : '*HVH-Replication' }
CooHistoryExperimentConfiguration class >> jrpc [
	"Project defined by the replication package: juliendelplanque/JRPC, branch master."

	^ self new
		  name: 'JRPC';
		  repository: 'https://github.com/juliendelplanque/JRPC.git';
		  numberOfCommits: 200;
		  packageNamePrefix: 'JRPC';
		  loader: [
			  Metacello new
				  baseline: 'JRPC';
				  repository: 'github://juliendelplanque/JRPC:master/src';
				  onConflict: [ :exception | exception useIncoming ];
				  onUpgrade: [ :exception | exception useIncoming ];
				  load ];
		  outputDirectory: FileLocator workingDirectory / 'History-Bench-Results' / 'JRPC';
		  yourself
]


{ #category : '*HVH-Replication' }
CooHistoryExperimentConfiguration class >> foliage [
	"Project defined by the replication package: noha/Foliage, branch main."

	^ self new
		  name: 'Foliage';
		  repository: 'https://github.com/noha/Foliage.git';
		  numberOfCommits: 200;
		  packageNamePrefix: 'Foliage';
		  loader: [
			  Metacello new
				  baseline: 'Foliage';
				  repository: 'github://noha/Foliage:main/src';
				  onConflict: [ :exception | exception useIncoming ];
				  onUpgrade: [ :exception | exception useIncoming ];
				  load ];
		  outputDirectory: FileLocator workingDirectory / 'History-Bench-Results' / 'Foliage';
		  yourself
]


{ #category : '*HVH-Replication' }
CooHistoryExperimentConfiguration class >> xmlParserHTML [
	"Project defined by the replication package: pharo-contributions/XML-XMLParserHTML, branch master."

	^ self new
		  name: 'XMLParserHTML';
		  repository: 'https://github.com/pharo-contributions/XML-XMLParserHTML.git';
		  numberOfCommits: 200;
		  packageNamePrefix: 'XMLParserHTML';
		  loader: [
			  Metacello new
				  baseline: 'XMLParserHTML';
				  repository: 'github://pharo-contributions/XML-XMLParserHTML:master/src';
				  onConflict: [ :exception | exception useIncoming ];
				  onUpgrade: [ :exception | exception useIncoming ];
				  load ];
		  outputDirectory: FileLocator workingDirectory / 'History-Bench-Results' / 'XMLParserHTML';
		  yourself
]


{ #category : '*HVH-Replication' }
CooHistoryExperimentConfiguration class >> pots [
	"Project defined by the replication package: robvanlopik/Pots, branch main."

	^ self new
		  name: 'Pots';
		  repository: 'https://github.com/robvanlopik/Pots.git';
		  numberOfCommits: 200;
		  packageNamePrefix: 'Pots';
		  loader: [
			  Metacello new
				  baseline: 'Pots';
				  repository: 'github://robvanlopik/Pots:main/src';
				  onConflict: [ :exception | exception useIncoming ];
				  onUpgrade: [ :exception | exception useIncoming ];
				  load ];
		  outputDirectory: FileLocator workingDirectory / 'History-Bench-Results' / 'Pots';
		  yourself
]


{ #category : '*HVH-Replication' }
CooHistoryExperimentConfiguration class >> aiDataInspector [
	"Project defined by the replication package: pharo-ai/data-inspector, branch master."

	^ self new
		  name: 'AIDataInspector';
		  repository: 'https://github.com/pharo-ai/data-inspector.git';
		  numberOfCommits: 200;
		  packageNamePrefix: 'AIDataFrameInspector';
		  loader: [
			  Metacello new
				  baseline: 'AIDataFrameInspector';
				  repository: 'github://pharo-ai/data-inspector:master/src';
				  onConflict: [ :exception | exception useIncoming ];
				  onUpgrade: [ :exception | exception useIncoming ];
				  load ];
		  outputDirectory: FileLocator workingDirectory / 'History-Bench-Results' / 'AIDataInspector';
		  yourself
]


{ #category : '*HVH-Replication' }
CooHistoryExperimentConfiguration class >> methodProxies [
	"Project defined by the replication package: pharo-contributions/MethodProxies, branch master."

	^ self new
		  name: 'MethodProxies';
		  repository: 'https://github.com/pharo-contributions/MethodProxies.git';
		  numberOfCommits: 200;
		  packageNamePrefix: 'MethodProxies';
		  loader: [
			  Metacello new
				  baseline: 'MethodProxies';
				  repository: 'github://pharo-contributions/MethodProxies:master/src';
				  onConflict: [ :exception | exception useIncoming ];
				  onUpgrade: [ :exception | exception useIncoming ];
				  load ];
		  outputDirectory: FileLocator workingDirectory / 'History-Bench-Results' / 'MethodProxies';
		  yourself
]


{ #category : '*HVH-Replication' }
CooHistoryExperimentConfiguration class >> mocketry [
	"Project defined by the replication package: dionisiydk/Mocketry, branch master."

	^ self new
		  name: 'Mocketry';
		  repository: 'https://github.com/dionisiydk/Mocketry.git';
		  numberOfCommits: 200;
		  packageNamePrefix: 'Mocketry';
		  loader: [
			  Metacello new
				  baseline: 'Mocketry';
				  repository: 'github://dionisiydk/Mocketry:master';
				  onConflict: [ :exception | exception useIncoming ];
				  onUpgrade: [ :exception | exception useIncoming ];
				  load ];
		  outputDirectory: FileLocator workingDirectory / 'History-Bench-Results' / 'Mocketry';
		  yourself
]


{ #category : '*HVH-Replication' }
CooHistoryExperimentConfiguration class >> punQLite [
	"Project defined by the replication package: mumez/PunQLite, branch develop."

	^ self new
		  name: 'PunQLite';
		  repository: 'https://github.com/mumez/PunQLite.git';
		  numberOfCommits: 200;
		  packageNamePrefix: 'PunQLite';
		  loader: [
			  Metacello new
				  baseline: 'PunQLite';
				  repository: 'github://mumez/PunQLite:develop/repository';
				  onConflict: [ :exception | exception useIncoming ];
				  onUpgrade: [ :exception | exception useIncoming ];
				  load ];
		  outputDirectory: FileLocator workingDirectory / 'History-Bench-Results' / 'PunQLite';
		  yourself
]


{ #category : '*HVH-Replication' }
CooHistoryExperimentConfiguration class >> zTimestamp [
	"Project defined by the replication package: svenvc/ztimestamp, branch master."

	^ self new
		  name: 'ZTimestamp';
		  repository: 'https://github.com/svenvc/ztimestamp.git';
		  numberOfCommits: 200;
		  packageNamePrefix: 'ZTimestamp';
		  loader: [
			  Metacello new
				  baseline: 'ZTimestamp';
				  repository: 'github://svenvc/ztimestamp:master/repository';
				  onConflict: [ :exception | exception useIncoming ];
				  onUpgrade: [ :exception | exception useIncoming ];
				  load ];
		  outputDirectory: FileLocator workingDirectory / 'History-Bench-Results' / 'ZTimestamp';
		  yourself
]


{ #category : '*HVH-Replication' }
CooHistoryExperimentConfiguration class >> novaStelo [
	"Project defined by the replication package: EiichiroIto/NovaStelo, branch master."

	^ self new
		  name: 'NovaStelo';
		  repository: 'https://github.com/EiichiroIto/NovaStelo.git';
		  numberOfCommits: 200;
		  packageNamePrefix: 'NovaStelo';
		  loader: [
			  Metacello new
				  baseline: 'NovaStelo';
				  repository: 'github://EiichiroIto/NovaStelo:master/src';
				  onConflict: [ :exception | exception useIncoming ];
				  onUpgrade: [ :exception | exception useIncoming ];
				  load ];
		  outputDirectory: FileLocator workingDirectory / 'History-Bench-Results' / 'NovaStelo';
		  yourself
]


{ #category : '*HVH-Replication' }
CooHistoryExperimentConfiguration class >> stateSpecs [
	"Project defined by the replication package: dionisiydk/StateSpecs, branch master."

	^ self new
		  name: 'StateSpecs';
		  repository: 'https://github.com/dionisiydk/StateSpecs.git';
		  numberOfCommits: 200;
		  packageNamePrefix: 'StateSpecs';
		  loader: [
			  Metacello new
				  baseline: 'StateSpecs';
				  repository: 'github://dionisiydk/StateSpecs:master';
				  onConflict: [ :exception | exception useIncoming ];
				  onUpgrade: [ :exception | exception useIncoming ];
				  load ];
		  outputDirectory: FileLocator workingDirectory / 'History-Bench-Results' / 'StateSpecs';
		  yourself
]


{ #category : '*HVH-Replication' }
CooHistoryExperimentConfiguration class >> pharoFunctional [
	"Project defined by the replication package: dvmason/Pharo-Functional, branch master."

	^ self new
		  name: 'PharoFunctional';
		  repository: 'https://github.com/dvmason/Pharo-Functional.git';
		  numberOfCommits: 200;
		  packageNamePrefix: 'PharoFunctional';
		  loader: [
			  Metacello new
				  baseline: 'PharoFunctional';
				  repository: 'github://dvmason/Pharo-Functional:master';
				  onConflict: [ :exception | exception useIncoming ];
				  onUpgrade: [ :exception | exception useIncoming ];
				  load ];
		  outputDirectory: FileLocator workingDirectory / 'History-Bench-Results' / 'PharoFunctional';
		  yourself
]


{ #category : '*HVH-Replication' }
CooHistoryExperimentConfiguration class >> hiedra [
	"Project defined by the replication package: tinchodias/hiedra, branch master."

	^ self new
		  name: 'Hiedra';
		  repository: 'https://github.com/tinchodias/hiedra.git';
		  numberOfCommits: 200;
		  packageNamePrefix: 'Hiedra';
		  loader: [
			  Metacello new
				  baseline: 'Hiedra';
				  repository: 'github://tinchodias/hiedra:master/src';
				  onConflict: [ :exception | exception useIncoming ];
				  onUpgrade: [ :exception | exception useIncoming ];
				  load ];
		  outputDirectory: FileLocator workingDirectory / 'History-Bench-Results' / 'Hiedra';
		  yourself
]

{ #category : '*HVH-Replication' }
CooHistoryExperimentConfiguration class >> artefact [
	"Project defined by the replication package: pharo-contributions/Artefact, branch development."

	^ self new
		  name: 'Artefact';
		  repository: 'https://github.com/pharo-contributions/Artefact.git';
		  numberOfCommits: 200;
		  packageNamePrefix: 'Artefact';
		  loader: [
			  Metacello new
				  baseline: 'Artefact';
				  repository: 'github://pharo-contributions/Artefact:development/src';
				  onConflict: [ :exception | exception useIncoming ];
				  onUpgrade: [ :exception | exception useIncoming ];
				  load ];
		  outputDirectory: FileLocator workingDirectory / 'History-Bench-Results' / 'Artefact';
		  yourself
]

{ #category : '*HVH-Replication' }
CooHistoryExperimentConfiguration class >> geoTools [
	"Project defined by the replication package: ThalesGroup/GeoTools, branch main."

	^ self new
		  name: 'GeoTools';
		  repository: 'https://github.com/ThalesGroup/GeoTools.git';
		  numberOfCommits: 200;
		  packageNamePrefix: 'GeoTools';
		  loader: [
			  Metacello new
				  baseline: 'GeoTools';
				  repository: 'github://ThalesGroup/GeoTools:main/src';
				  onConflict: [ :exception | exception useIncoming ];
				  onUpgrade: [ :exception | exception useIncoming ];
				  load ];
		  outputDirectory: FileLocator workingDirectory / 'History-Bench-Results' / 'GeoTools';
		  yourself
]

{ #category : '*HVH-Replication' }
CooHistoryExperimentConfiguration class >> meilisearch [
	"Project defined by the replication package: mumez/Meilisearch.st, branch develop."

	^ self new
		  name: 'Meilisearch';
		  repository: 'https://github.com/mumez/Meilisearch.st.git';
		  numberOfCommits: 200;
		  packageNamePrefix: 'Meilisearch';
		  loader: [
			  Metacello new
				  baseline: 'Meilisearch';
				  repository: 'github://mumez/Meilisearch.st:develop/src';
				  onConflict: [ :exception | exception useIncoming ];
				  onUpgrade: [ :exception | exception useIncoming ];
				  load ];
		  outputDirectory: FileLocator workingDirectory / 'History-Bench-Results' / 'Meilisearch';
		  yourself
]

{ #category : '*HVH-Replication' }
CooHistoryExperimentConfiguration class >> historia [
	"Project defined by the replication package: mumez/Historia, branch develop."

	^ self new
		  name: 'Historia';
		  repository: 'https://github.com/mumez/Historia.git';
		  numberOfCommits: 200;
		  packageNamePrefix: 'Historia';
		  loader: [
			  Metacello new
				  baseline: 'Historia';
				  repository: 'github://mumez/Historia:develop/src';
				  onConflict: [ :exception | exception useIncoming ];
				  onUpgrade: [ :exception | exception useIncoming ];
				  load ];
		  outputDirectory: FileLocator workingDirectory / 'History-Bench-Results' / 'Historia';
		  yourself
]

{ #category : '*HVH-Replication' }
CooHistoryExperimentConfiguration class >> packageFormulas [
	"Project defined by the replication package: hernanmd/package-formulas, branch master."

	^ self new
		  name: 'PackageFormulas';
		  repository: 'https://github.com/hernanmd/package-formulas.git';
		  numberOfCommits: 200;
		  packageNamePrefix: 'PackageFormulas';
		  loader: [
			  Metacello new
				  baseline: 'PackageFormulas';
				  repository: 'github://hernanmd/package-formulas:master/src';
				  onConflict: [ :exception | exception useIncoming ];
				  onUpgrade: [ :exception | exception useIncoming ];
				  load ];
		  outputDirectory: FileLocator workingDirectory / 'History-Bench-Results' / 'PackageFormulas';
		  yourself
]

{ #category : '*HVH-Replication' }
CooHistoryExperimentConfiguration class >> micromaid [
	"Project defined by the replication package: tomooda/Micromaid, branch main."

	^ self new
		  name: 'Micromaid';
		  repository: 'https://github.com/tomooda/Micromaid.git';
		  numberOfCommits: 200;
		  packageNamePrefix: 'Micromaid';
		  loader: [
			  Metacello new
				  baseline: 'Micromaid';
				  repository: 'github://tomooda/Micromaid:main/src';
				  onConflict: [ :exception | exception useIncoming ];
				  onUpgrade: [ :exception | exception useIncoming ];
				  load ];
		  outputDirectory: FileLocator workingDirectory / 'History-Bench-Results' / 'Micromaid';
		  yourself
]

{ #category : '*HVH-Replication' }
CooHistoryExperimentConfiguration class >> sauco [
	"Project defined by the replication package: tinchodias/Sauco, branch master."

	^ self new
		  name: 'Sauco';
		  repository: 'https://github.com/tinchodias/Sauco.git';
		  numberOfCommits: 200;
		  packageNamePrefix: 'Sauco';
		  loader: [
			  Metacello new
				  baseline: 'Sauco';
				  repository: 'github://tinchodias/Sauco:master/src';
				  onConflict: [ :exception | exception useIncoming ];
				  onUpgrade: [ :exception | exception useIncoming ];
				  load ];
		  outputDirectory: FileLocator workingDirectory / 'History-Bench-Results' / 'Sauco';
		  yourself
]

{ #category : '*HVH-Replication' }
CooHistoryExperimentConfiguration class >> ffiCallLogger [
	"Project defined by the replication package: tinchodias/FFICallLogger, branch master."

	^ self new
		  name: 'FFICallLogger';
		  repository: 'https://github.com/tinchodias/FFICallLogger.git';
		  numberOfCommits: 200;
		  packageNamePrefix: 'FFICallLogger';
		  loader: [
			  Metacello new
				  baseline: 'FFICallLogger';
				  repository: 'github://tinchodias/FFICallLogger:master';
				  onConflict: [ :exception | exception useIncoming ];
				  onUpgrade: [ :exception | exception useIncoming ];
				  load ];
		  outputDirectory: FileLocator workingDirectory / 'History-Bench-Results' / 'FFICallLogger';
		  yourself
]

{ #category : '*HVH-Replication' }
CooHistoryExperimentConfiguration class >> jsonWebToken [
	"Project defined by the replication package: noha/JSONWebToken, branch master."

	^ self new
		  name: 'JSONWebToken';
		  repository: 'https://github.com/noha/JSONWebToken.git';
		  numberOfCommits: 200;
		  packageNamePrefix: 'JSONWebToken';
		  loader: [
			  Metacello new
				  baseline: 'JSONWebToken';
				  repository: 'github://noha/JSONWebToken:master/source';
				  onConflict: [ :exception | exception useIncoming ];
				  onUpgrade: [ :exception | exception useIncoming ];
				  load ];
		  outputDirectory: FileLocator workingDirectory / 'History-Bench-Results' / 'JSONWebToken';
		  yourself
]

{ #category : '*HVH-Replication' }
CooHistoryExperimentConfiguration class >> chartJs [
	"Project defined by the replication package: DuneSt/ChartJs, branch development."

	^ self new
		  name: 'ChartJs';
		  repository: 'https://github.com/DuneSt/ChartJs.git';
		  numberOfCommits: 200;
		  packageNamePrefix: 'ChartJs';
		  loader: [
			  Metacello new
				  baseline: 'ChartJs';
				  repository: 'github://DuneSt/ChartJs:development/src';
				  onConflict: [ :exception | exception useIncoming ];
				  onUpgrade: [ :exception | exception useIncoming ];
				  load ];
		  outputDirectory: FileLocator workingDirectory / 'History-Bench-Results' / 'ChartJs';
		  yourself
]

{ #category : '*HVH-Replication' }
CooHistoryExperimentConfiguration class >> mustache [
	"Project defined by the replication package: noha/mustache, branch master."

	^ self new
		  name: 'Mustache';
		  repository: 'https://github.com/noha/mustache.git';
		  numberOfCommits: 200;
		  packageNamePrefix: 'Mustache';
		  loader: [
			  Metacello new
				  baseline: 'Mustache';
				  repository: 'github://noha/mustache:master/repository';
				  onConflict: [ :exception | exception useIncoming ];
				  onUpgrade: [ :exception | exception useIncoming ];
				  load ];
		  outputDirectory: FileLocator workingDirectory / 'History-Bench-Results' / 'Mustache';
		  yourself
]

{ #category : '*HVH-Replication' }
CooHistoryExperimentConfiguration class >> pharoOWS [
	"Project defined by the replication package: ThalesGroup/PharoOWS, branch main."

	^ self new
		  name: 'PharoOWS';
		  repository: 'https://github.com/ThalesGroup/PharoOWS.git';
		  numberOfCommits: 200;
		  packageNamePrefix: 'OWS';
		  loader: [
			  Metacello new
				  baseline: 'OWS';
				  repository: 'github://ThalesGroup/PharoOWS:main/src';
				  onConflict: [ :exception | exception useIncoming ];
				  onUpgrade: [ :exception | exception useIncoming ];
				  load ];
		  outputDirectory: FileLocator workingDirectory / 'History-Bench-Results' / 'PharoOWS';
		  yourself
]

{ #category : '*HVH-Replication' }
CooHistoryExperimentConfiguration class >> illimani [
	"Project defined by the replication package: jordanmontt/illimani-memory-profiler, branch main."

	^ self new
		  name: 'Illimani';
		  repository: 'https://github.com/jordanmontt/illimani-memory-profiler.git';
		  numberOfCommits: 200;
		  packageNamePrefix: 'IllimaniProfiler';
		  loader: [
			  Metacello new
				  baseline: 'IllimaniProfiler';
				  repository: 'github://jordanmontt/illimani-memory-profiler:main/src';
				  onConflict: [ :exception | exception useIncoming ];
				  onUpgrade: [ :exception | exception useIncoming ];
				  load ];
		  outputDirectory: FileLocator workingDirectory / 'History-Bench-Results' / 'Illimani';
		  yourself
]

{ #category : '*HVH-Replication' }
CooHistoryExperimentConfiguration class >> chrome [
	"Project defined by the replication package: astares/Pharo-Chrome, branch main."

	^ self new
		  name: 'Chrome';
		  repository: 'https://github.com/astares/Pharo-Chrome.git';
		  numberOfCommits: 200;
		  packageNamePrefix: 'Chrome';
		  loader: [
			  Metacello new
				  baseline: 'Chrome';
				  repository: 'github://astares/Pharo-Chrome:main/src';
				  onConflict: [ :exception | exception useIncoming ];
				  onUpgrade: [ :exception | exception useIncoming ];
				  load ];
		  outputDirectory: FileLocator workingDirectory / 'History-Bench-Results' / 'Chrome';
		  yourself
]

{ #category : '*HVH-Replication' }
CooHistoryExperimentConfiguration class >> pharoMisc [
	"Project defined by the replication package: bouraqadi/PharoMisc, branch pharo12."

	^ self new
		  name: 'PharoMisc';
		  repository: 'https://github.com/bouraqadi/PharoMisc.git';
		  numberOfCommits: 200;
		  packageNamePrefix: 'PharoMisc';
		  loader: [
			  Metacello new
				  baseline: 'PharoMisc';
				  repository: 'github://bouraqadi/PharoMisc:pharo12/Pharo';
				  onConflict: [ :exception | exception useIncoming ];
				  onUpgrade: [ :exception | exception useIncoming ];
				  load ];
		  outputDirectory: FileLocator workingDirectory / 'History-Bench-Results' / 'PharoMisc';
		  yourself
]
