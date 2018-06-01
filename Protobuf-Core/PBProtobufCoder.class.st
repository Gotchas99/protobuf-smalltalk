Class {
	#name : #PBProtobufCoder,
	#superclass : #Object,
	#category : #'Protobuf-Core'
}

{ #category : #'coder-length-delimited' }
PBProtobufCoder class >> decodeUtf8: aString [

	^ ZnUTF8Encoder default decodeBytes: aString
]

{ #category : #'coder-varint' }
PBProtobufCoder class >> decodeVarint32: aByteArray [

	^ self readVarint32: aByteArray readStream
]

{ #category : #'coder-varint' }
PBProtobufCoder class >> decodeVarint64: aByteArray [

	^ self readVarint64: aByteArray readStream
]

{ #category : #'coder-varint' }
PBProtobufCoder class >> decodeZigZag32: anInteger [

	^(anInteger bitAt: 1) = 0
			ifTrue: [ anInteger >> 1 ]
			ifFalse: [ ((anInteger + 1) >> 1) negated ]	
]

{ #category : #'coder-varint' }
PBProtobufCoder class >> decodeZigZag64: anInteger [

	^(anInteger bitAt: 1) = 0
			ifTrue: [ anInteger >> 1 ]
			ifFalse: [ ((anInteger + 1) >> 1) negated ]	
]

{ #category : #'coder-length-delimited' }
PBProtobufCoder class >> encodeUtf8: aString [

	^ ZnUTF8Encoder default encodeString: aString
]

{ #category : #'coder-varint' }
PBProtobufCoder class >> encodeVarint32: anInteger [

	^ ByteArray streamContents: [ :s | self writeVarint32: anInteger on: s ]
]

{ #category : #'coder-varint' }
PBProtobufCoder class >> encodeVarint64: anInteger [

	^ ByteArray streamContents: [ :s | self writeVarint64: anInteger on: s ]
]

{ #category : #'coder-varint' }
PBProtobufCoder class >> encodeZigZag32: anInteger [

	^ anInteger >= 0
			ifTrue: [ (anInteger << 1) ]
			ifFalse: [ (anInteger negated << 1) - 1 ]
]

{ #category : #'coder-varint' }
PBProtobufCoder class >> encodeZigZag64: anInteger [

	^ anInteger >= 0
			ifTrue: [ (anInteger << 1) ]
			ifFalse: [ (anInteger negated << 1) - 1 ]	
]

{ #category : #'coder-varint' }
PBProtobufCoder class >> readVarint32: aByteStream [

	| val |
	
	val := self readVarintRaw: aByteStream.
	
	^val < 16r80000000
		ifTrue: [ val ]
		ifFalse: [ val - 16r100000000 ]
]

{ #category : #'coder-varint' }
PBProtobufCoder class >> readVarint64: aByteStream [

	| val |
	
	val := self readVarintRaw: aByteStream.
	
	^val < 16r8000000000000000
		ifTrue: [ val ]
		ifFalse: [ val - 16r10000000000000000 ]
]

{ #category : #'coder-varint' }
PBProtobufCoder class >> readVarintRaw: aByteStream [

	| val byte shift |
	
	val := 0.
	shift := 0.
		
	[ 	byte := aByteStream next.
		byte isNil
			ifTrue: [ self error: 'Invalid protobuf stream' ].
		val := val + ((byte bitAnd: 16r7F) << shift).
		byte < 128 ]
			whileFalse: [ shift := shift + 7 ].
	^ val
]

{ #category : #'coder-varint' }
PBProtobufCoder class >> writeVarint32: anInteger on: aByteStream [

	self writeVarintRaw: (
			anInteger < 0
				ifTrue: [ 16r100000000 + anInteger ]
				ifFalse: [ anInteger ])
		on: aByteStream
]

{ #category : #'coder-varint' }
PBProtobufCoder class >> writeVarint64: anInteger on: aByteStream [

	self writeVarintRaw: (
			anInteger < 0
				ifTrue: [ 16r10000000000000000 + anInteger ]
				ifFalse: [ anInteger ])
		on: aByteStream
]

{ #category : #'coder-varint' }
PBProtobufCoder class >> writeVarintRaw: aPositiveInteger on: aByteStream [

	| val |
	
	val := aPositiveInteger.
	[ true ]
		whileTrue: [ 
			val < 128
				ifTrue: [ 
					aByteStream nextPut: val.
					^self ]
				ifFalse: [ 
					aByteStream nextPut: (val bitAnd: 16r7F) + 16r80.
					val := val >> 7 ] ]
]