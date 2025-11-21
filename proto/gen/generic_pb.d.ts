import * as jspb from 'google-protobuf'



export class Empty extends jspb.Message {
  serializeBinary(): Uint8Array;
  toObject(includeInstance?: boolean): Empty.AsObject;
  static toObject(includeInstance: boolean, msg: Empty): Empty.AsObject;
  static serializeBinaryToWriter(message: Empty, writer: jspb.BinaryWriter): void;
  static deserializeBinary(bytes: Uint8Array): Empty;
  static deserializeBinaryFromReader(message: Empty, reader: jspb.BinaryReader): Empty;
}

export namespace Empty {
  export type AsObject = {
  };
}

export class Optional extends jspb.Message {
  getValue(): string;
  setValue(value: string): Optional;
  hasValue(): boolean;
  clearValue(): Optional;

  serializeBinary(): Uint8Array;
  toObject(includeInstance?: boolean): Optional.AsObject;
  static toObject(includeInstance: boolean, msg: Optional): Optional.AsObject;
  static serializeBinaryToWriter(message: Optional, writer: jspb.BinaryWriter): void;
  static deserializeBinary(bytes: Uint8Array): Optional;
  static deserializeBinaryFromReader(message: Optional, reader: jspb.BinaryReader): Optional;
}

export namespace Optional {
  export type AsObject = {
    value?: string;
  };

  export const enum ValueCase {
    _VALUE_NOT_SET = 0,
    VALUE = 1,
  }
}

