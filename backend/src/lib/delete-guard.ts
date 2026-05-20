export class DeleteBlockedError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "DeleteBlockedError";
  }
}
