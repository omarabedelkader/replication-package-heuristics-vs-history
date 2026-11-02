Extension { #name : 'CooHistoryExperimentConfiguration' }

{ #category : '*HVH-Replication' }
CooHistoryExperimentConfiguration class >> soil [
	"Extra project of the replication package (not in the paper): ApptiveGrid/Soil, branch main."

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
	"Extra project of the replication package (not in the paper): OpenSmock/Molecule, branch main."

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
	"Extra project of the replication package (not in the paper): OpenSmock/Pyramid, branch main."

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
	"Extra project of the replication package (not in the paper): TelescopeSt/Telescope, branch development."

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
	"Extra project of the replication package (not in the paper): pharo-contributions/XML-XMLParser, branch master."

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
	"Extra project of the replication package (not in the paper): DuneSt/MaterialDesignLite, branch development."

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
	"Extra project of the replication package (not in the paper): cormas/cormas, branch master."

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
	"Extra project of the replication package (not in the paper): pharo-contributions/mutalk, branch master."

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
	"Extra project of the replication package (not in the paper): lucretiomsp/Coypu, branch master."

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
	"Extra project of the replication package (not in the paper): badetitou/Pharo-LanguageServer, branch v6."

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
	"Extra project of the replication package (not in the paper): moosetechnology/FAST, branch v3."

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
	"Extra project of the replication package (not in the paper): moosetechnology/MoTion, branch main."

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
	"Extra project of the replication package (not in the paper): pharo-ai/graph-algorithms, branch master."

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
	"Extra project of the replication package (not in the paper): kursjan/petitparser2, branch master."

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
	"Extra project of the replication package (not in the paper): pharo-contributions/taskit, branch master."

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
	"Extra project of the replication package (not in the paper): ErikOnBike/CodeParadise, branch master."

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
	"Extra project of the replication package (not in the paper): svenvc/P3, branch master."

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
	"Extra project of the replication package (not in the paper): ApptiveGrid/OpenAPI, branch master."

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
	"Extra project of the replication package (not in the paper): pharo-nosql/mongotalk, branch master."

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
	"Extra project of the replication package (not in the paper): SeasideSt/Grease, branch master."

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
	"Extra project of the replication package (not in the paper): SeasideSt/Parasol, branch master."

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
	"Extra project of the replication package (not in the paper): svenvc/NeoCSV, branch master."

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
	"Extra project of the replication package (not in the paper): svenvc/NeoJSON, branch master."

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
	"Extra project of the replication package (not in the paper): rko281/ReStoreForPharo, branch main."

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
