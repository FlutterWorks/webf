// https://microsoft.github.io/debug-adapter-protocol/specification#Base_Protocol_Request

interface Request {
  /**
   * Sequence number of the message (also known as message ID). The `seq` for
   * the first message sent by a client or debug adapter is 1, and for each
   * subsequent message is 1 greater than the previous message sent by that
   * actor. `seq` can be used to order requests, responses, and events, and to
   * associate requests with their corresponding responses. For protocol
   * messages of type `request` the sequence number can be used to cancel the
   * request.
   */
  seq: int64;

  type: 'request';

  /**
   * The command to execute.
   */
  command: string;

  /**
   * Object containing arguments for the command.
   */
  arguments?: any;
}

interface AttachRequestArguments {
  /**
   * Arbitrary data from the previous, restarted session.
   * The data is sent as the `restart` attribute of the `terminated` event.
   * The client should leave the data intact.
   */
  __restart?: any;
}

interface ValueFormat {
  /**
   * Display the value in hex.
   */
  hex?: boolean;
}

interface EvaluateArguments {
  /**
   * The expression to evaluate.
   */
  expression: string;

  /**
   * Evaluate the expression in the scope of this stack frame. If not specified,
   * the expression is evaluated in the global scope.
   */
  frameId?: int64;

  /**
   * The context in which the evaluate request is used.
   * Values:
   * 'watch': evaluate is called from a watch view context.
   * 'repl': evaluate is called from a REPL context.
   * 'hover': evaluate is called to generate the debug hover contents.
   * This value should only be used if the corresponding capability
   * `supportsEvaluateForHovers` is true.
   * 'clipboard': evaluate is called to generate clipboard contents.
   * This value should only be used if the corresponding capability
   * `supportsClipboardContext` is true.
   * 'variables': evaluate is called from a variables view context.
   * etc.
   */
  context?: string;

  /**
   * Specifies details on how to format the result.
   * The attribute is only honored by a debug adapter if the corresponding
   * capability `supportsValueFormattingOptions` is true.
   */
  format?: ValueFormat;
}

interface EvaluateRequest extends Request {
  command: 'evaluate';

  arguments: EvaluateArguments;
}

interface Event {
  /**
   * Sequence number of the message (also known as message ID). The `seq` for
   * the first message sent by a client or debug adapter is 1, and for each
   * subsequent message is 1 greater than the previous message sent by that
   * actor. `seq` can be used to order requests, responses, and events, and to
   * associate requests with their corresponding responses. For protocol
   * messages of type `request` the sequence number can be used to cancel the
   * request.
   */
  seq: int64;

  type: 'event';

  /**
   * Type of event.
   */
  event: string;

  /**
   * Event-specific information.
   */
  body?: any;
}

interface StoppedEventBody {
  /**
   * The reason for the event.
   * For backward compatibility this string is shown in the UI if the
   * `description` attribute is missing (but it must not be translated).
   * Values: 'step', 'breakpoint', 'exception', 'pause', 'entry', 'goto',
   * 'function breakpoint', 'data breakpoint', 'instruction breakpoint', etc.
   */
  reason: string;

  /**
   * The full reason for the event, e.g. 'Paused on exception'. This string is
   * shown in the UI as is and can be translated.
   */
  description?: string;

  /**
   * The thread which was stopped.
   */
  threadId?: int64;

  /**
   * A value of true hints to the client that this event should not change the
   * focus.
   */
  preserveFocusHint?: boolean;

  /**
   * Additional information. E.g. if reason is `exception`, text contains the
   * exception name. This string is shown in the UI.
   */
  text?: string;

  /**
   * If `allThreadsStopped` is true, a debug adapter can announce that all
   * threads have stopped.
   * - The client should use this information to enable that all threads can
   * be expanded to access their stacktraces.
   * - If the attribute is missing or false, only the thread with the given
   * `threadId` can be expanded.
   */
  allThreadsStopped?: boolean;

  /**
   * Ids of the breakpoints that triggered the event. In most cases there is
   * only a single breakpoint but here are some examples for multiple
   * breakpoints:
   * - Different types of breakpoints map to the same location.
   * - Multiple source breakpoints get collapsed to the same instruction by
   * the compiler/runtime.
   * - Multiple function breakpoints with different function names map to the
   * same location.
   */
  hitBreakpointIds?: number[];
}

interface StoppedEvent extends Event {
  event: 'stopped';
  body: StoppedEventBody;
}

interface Response {
  /**
   * Sequence number of the message (also known as message ID). The `seq` for
   * the first message sent by a client or debug adapter is 1, and for each
   * subsequent message is 1 greater than the previous message sent by that
   * actor. `seq` can be used to order requests, responses, and events, and to
   * associate requests with their corresponding responses. For protocol
   * messages of type `request` the sequence number can be used to cancel the
   * request.
   */
  seq: int64;

  type: 'response';

  /**
   * Sequence number of the corresponding request.
   */
  request_seq: int64;

  /**
   * Outcome of the request.
   * If true, the request was successful and the `body` attribute may contain
   * the result of the request.
   * If the value is false, the attribute `message` contains the error in short
   * form and the `body` may contain additional information (see
   * `ErrorResponse.body.error`).
   */
  success: boolean;

  /**
   * The command requested.
   */
  command: string;

  /**
   * Contains the raw error in short form if `success` is false.
   * This raw error might be interpreted by the client and is not shown in the
   * UI.
   * Some predefined values exist.
   * Values:
   * 'cancelled': the request was cancelled.
   * 'notStopped': the request may be retried once the adapter is in a 'stopped'
   * state.
   * etc.
   */
  message?: 'cancelled' | 'notStopped' | string;

  /**
   * Contains request result if success is true and error details if success is
   * false.
   */
  body?: any;
}

interface VariablePresentationHint {
  /**
   * The kind of variable. Before introducing additional values, try to use the
   * listed values.
   * Values:
   * 'property': Indicates that the object is a property.
   * 'method': Indicates that the object is a method.
   * 'class': Indicates that the object is a class.
   * 'data': Indicates that the object is data.
   * 'event': Indicates that the object is an event.
   * 'baseClass': Indicates that the object is a base class.
   * 'innerClass': Indicates that the object is an inner class.
   * 'interface': Indicates that the object is an interface.
   * 'mostDerivedClass': Indicates that the object is the most derived class.
   * 'virtual': Indicates that the object is virtual, that means it is a
   * synthetic object introduced by the adapter for rendering purposes, e.g. an
   * index range for large arrays.
   * 'dataBreakpoint': Deprecated: Indicates that a data breakpoint is
   * registered for the object. The `hasDataBreakpoint` attribute should
   * generally be used instead.
   * etc.
   */
  kind?: string;

  /**
   * Set of attributes represented as an array of strings. Before introducing
   * additional values, try to use the listed values.
   * Values:
   * 'static': Indicates that the object is static.
   * 'constant': Indicates that the object is a constant.
   * 'readOnly': Indicates that the object is read only.
   * 'rawString': Indicates that the object is a raw string.
   * 'hasObjectId': Indicates that the object can have an Object ID created for
   * it.
   * 'canHaveObjectId': Indicates that the object has an Object ID associated
   * with it.
   * 'hasSideEffects': Indicates that the evaluation had side effects.
   * 'hasDataBreakpoint': Indicates that the object has its value tracked by a
   * data breakpoint.
   * etc.
   */
  attributes?: string[];

  /**
   * Visibility of variable. Before introducing additional values, try to use
   * the listed values.
   * Values: 'public', 'private', 'protected', 'internal', 'final', etc.
   */
  visibility?:  string;

  /**
   * If true, clients can present the variable with a UI that supports a
   * specific gesture to trigger its evaluation.
   * This mechanism can be used for properties that require executing code when
   * retrieving their value and where the code execution can be expensive and/or
   * produce side-effects. A typical example are properties based on a getter
   * function.
   * Please note that in addition to the `lazy` flag, the variable's
   * `variablesReference` is expected to refer to a variable that will provide
   * the value through another `variable` request.
   */
  lazy?: boolean;
}

interface EvaluateResponseBody {
  /**
   * The result of the evaluate request.
   */
  result: string;

  /**
   * The type of the evaluate result.
   * This attribute should only be returned by a debug adapter if the
   * corresponding capability `supportsVariableType` is true.
   */
  type?: string;

  /**
   * Properties of an evaluate result that can be used to determine how to
   * render the result in the UI.
   */
  presentationHint?: VariablePresentationHint;

  /**
   * If `variablesReference` is > 0, the evaluate result is structured and its
   * children can be retrieved by passing `variablesReference` to the
   * `variables` request as long as execution remains suspended. See 'Lifetime
   * of Object References' in the Overview section for details.
   */
  variablesReference: int64;

  /**
   * The number of named child variables.
   * The client can use this information to present the variables in a paged
   * UI and fetch them in chunks.
   * The value should be less than or equal to 2147483647 (2^31-1).
   */
  namedVariables?: number;

  /**
   * The number of indexed child variables.
   * The client can use this information to present the variables in a paged
   * UI and fetch them in chunks.
   * The value should be less than or equal to 2147483647 (2^31-1).
   */
  indexedVariables?: number;

  /**
   * A memory reference to a location appropriate for this result.
   * For pointer type eval results, this is generally a reference to the
   * memory address contained in the pointer.
   * This attribute should be returned by a debug adapter if corresponding
   * capability `supportsMemoryReferences` is true.
   */
  memoryReference?: string;
}

interface EvaluateResponse extends Response {
  body: EvaluateResponseBody;
}

interface ContinueArguments {
  /**
   * Specifies the active thread. If the debug adapter supports single thread
   * execution (see `supportsSingleThreadExecutionRequests`) and the argument
   * `singleThread` is true, only the thread with this ID is resumed.
   */
  threadId: number;

  /**
   * If this flag is true, execution is resumed only for the thread with given
   * `threadId`.
   */
  singleThread?: boolean;
}

interface ContinueRequest extends Request {
  command: 'continue';

  arguments: ContinueArguments;
}

interface ContinueResponseBody {
  /**
   * The value true (or a missing property) signals to the client that all
   * threads have been resumed. The value false indicates that not all threads
   * were resumed.
   */
  allThreadsContinued?: boolean;
}

interface ContinueResponse extends Response {
  body: ContinueResponseBody;
}

interface PauseArguments {
  /**
   * Pause execution for this thread.
   */
  threadId: int64;
}

interface PauseRequest extends Request {
  command: 'pause';

  arguments: PauseArguments;
}

interface PauseResponseBody {}

interface PauseResponse extends Response {
  body: PauseResponseBody;
}

interface NextArguments {
  /**
   * Specifies the thread for which to resume execution for one step (of the
   * given granularity).
   */
  threadId: int64;

  /**
   * If this flag is true, all other suspended threads are not resumed.
   */
  singleThread?: boolean;

  // /**
  //  * Stepping granularity. If no granularity is specified, a granularity of
  //  * `statement` is assumed.
  //  */
  // granularity?: SteppingGranularity;
}

interface NextRequest extends Request {
  command: 'next';

  arguments: NextArguments;
}

interface NextResponseBody {}

interface NextResponse extends Response {
  body: NextResponseBody;
}

interface StepInArguments {
  /**
   * Specifies the thread for which to resume execution for one step-into (of
   * the given granularity).
   */
  threadId: int64;

  /**
   * If this flag is true, all other suspended threads are not resumed.
   */
  singleThread?: boolean;

  /**
   * Id of the target to step into.
   */
  targetId?: int64;

  // /**
  //  * Stepping granularity. If no granularity is specified, a granularity of
  //  * `statement` is assumed.
  //  */
  // granularity?: SteppingGranularity;
}

interface StepInRequest extends Request {
  command: 'stepIn';

  arguments: StepInArguments;
}

interface StepInResponseBody {}

interface StepInResponse extends Response {
  body: StepInResponseBody;
}

interface StepOutArguments {
  /**
   * Specifies the thread for which to resume execution for one step-out (of the
   * given granularity).
   */
  threadId: int64;

  /**
   * If this flag is true, all other suspended threads are not resumed.
   */
  singleThread?: boolean;

  // /**
  //  * Stepping granularity. If no granularity is specified, a granularity of
  //  * `statement` is assumed.
  //  */
  // granularity?: SteppingGranularity;
}

interface StepOutRequest extends Request {
  command: 'stepOut';

  arguments: StepOutArguments;
}

interface StepOutResponseBody {}

interface StepOutResponse extends Response {
  body: StepInResponseBody;
}

interface StackFrameFormat extends ValueFormat {
  /**
   * Displays parameters for the stack frame.
   */
  parameters?: boolean;

  /**
   * Displays the types of parameters for the stack frame.
   */
  parameterTypes?: boolean;

  /**
   * Displays the names of parameters for the stack frame.
   */
  parameterNames?: boolean;

  /**
   * Displays the values of parameters for the stack frame.
   */
  parameterValues?: boolean;

  /**
   * Displays the line number of the stack frame.
   */
  line?: boolean;

  /**
   * Displays the module of the stack frame.
   */
  module?: boolean;

  /**
   * Includes all stack frames, including those the debug adapter might
   * otherwise hide.
   */
  includeAll?: boolean;
}

interface StackTraceArguments {
  /**
   * Retrieve the stacktrace for this thread.
   */
  threadId: number;

  /**
   * The index of the first frame to return; if omitted frames start at 0.
   */
  startFrame?: number;

  /**
   * The maximum number of frames to return. If levels is not specified or 0,
   * all frames are returned.
   */
  levels?: number;

  /**
   * Specifies details on how to format the stack frames.
   * The attribute is only honored by a debug adapter if the corresponding
   * capability `supportsValueFormattingOptions` is true.
   */
  format?: StackFrameFormat;
}

interface Checksum {
  /**
   * The algorithm used to calculate this checksum.
   */
  algorithm: string;

  /**
   * Value of the checksum, encoded as a hexadecimal value.
   */
  checksum: string;
}

interface Source {
  /**
   * The short name of the source. Every source returned from the debug adapter
   * has a name.
   * When sending a source to the debug adapter this name is optional.
   */
  name?: string;

  /**
   * The path of the source to be shown in the UI.
   * It is only used to locate and load the content of the source if no
   * `sourceReference` is specified (or its value is 0).
   */
  path?: string;

  /**
   * If the value > 0 the contents of the source must be retrieved through the
   * `source` request (even if a path is specified).
   * Since a `sourceReference` is only valid for a session, it can not be used
   * to persist a source.
   * The value should be less than or equal to 2147483647 (2^31-1).
   */
  sourceReference?: number;

  /**
   * A hint for how to present the source in the UI.
   * A value of `deemphasize` can be used to indicate that the source is not
   * available or that it is skipped on stepping.
   * Values: 'normal', 'emphasize', 'deemphasize'
   */
  presentationHint?: string;

  /**
   * The origin of this source. For example, 'internal module', 'inlined content
   * from source map', etc.
   */
  origin?: string;

  /**
   * A list of sources that are related to this source. These may be the source
   * that generated this source.
   */
  sources?: Source[];

  /**
   * Additional data that a debug adapter might want to loop through the client.
   * The client should leave the data intact and persist it across sessions. The
   * client should not interpret the data.
   */
  adapterData?: any;

  /**
   * The checksums associated with this file.
   */
  checksums?: Checksum[];
}

interface StackFrame {
  /**
   * An identifier for the stack frame. It must be unique across all threads.
   * This id can be used to retrieve the scopes of the frame with the `scopes`
   * request or to restart the execution of a stack frame.
   */
  id: number;

  /**
   * The name of the stack frame, typically a method name.
   */
  name: string;

  /**
   * The source of the frame.
   */
  source?: Source;

  /**
   * The line within the source of the frame. If the source attribute is missing
   * or doesn't exist, `line` is 0 and should be ignored by the client.
   */
  line: number;

  /**
   * Start position of the range covered by the stack frame. It is measured in
   * UTF-16 code units and the client capability `columnsStartAt1` determines
   * whether it is 0- or 1-based. If attribute `source` is missing or doesn't
   * exist, `column` is 0 and should be ignored by the client.
   */
  column: number;

  /**
   * The end line of the range covered by the stack frame.
   */
  endLine?: number;

  /**
   * End position of the range covered by the stack frame. It is measured in
   * UTF-16 code units and the client capability `columnsStartAt1` determines
   * whether it is 0- or 1-based.
   */
  endColumn?: number;

  /**
   * Indicates whether this frame can be restarted with the `restart` request.
   * Clients should only use this if the debug adapter supports the `restart`
   * request and the corresponding capability `supportsRestartRequest` is true.
   */
  canRestart?: boolean;

  /**
   * A memory reference for the current instruction pointer in this frame.
   */
  instructionPointerReference?: string;

  /**
   * The module associated with this frame, if any.
   */
  moduleId?: number | string;

  /**
   * A hint for how to present this frame in the UI.
   * A value of `label` can be used to indicate that the frame is an artificial
   * frame that is used as a visual label or separator. A value of `subtle` can
   * be used to change the appearance of a frame in a 'subtle' way.
   * Values: 'normal', 'label', 'subtle'
   */
  presentationHint?: string;
}

interface StackTraceResponseBody {
  /**
   * The frames of the stack frame. If the array has length zero, there are no
   * stack frames available.
   * This means that there is no location information available.
   */
  stackFrames: StackFrame[];

  /**
   * The total number of frames available in the stack. If omitted or if
   * `totalFrames` is larger than the available frames, a client is expected
   * to request frames until a request returns less frames than requested
   * (which indicates the end of the stack). Returning monotonically
   * increasing `totalFrames` values for subsequent requests can be used to
   * enforce paging in the client.
   */
  totalFrames?: int64;
}

interface StackTraceRequest extends Request {
  command: 'stackTrace';

  arguments: StackTraceArguments;
}

interface StackTraceResponse extends Response {
  body: StackTraceResponseBody;
}

interface ScopesArguments {
  /**
   * Retrieve the scopes for the stack frame identified by `frameId`. The
   * `frameId` must have been obtained in the current suspended state. See
   * 'Lifetime of Object References' in the Overview section for details.
   */
  frameId: int64;
}

interface ScopesRequest extends Request {
  command: 'scopes';

  arguments: ScopesArguments;
}

interface Scope {
  /**
   * Name of the scope such as 'Arguments', 'Locals', or 'Registers'. This
   * string is shown in the UI as is and can be translated.
   */
  name: string;

  /**
   * A hint for how to present this scope in the UI. If this attribute is
   * missing, the scope is shown with a generic UI.
   * Values:
   * 'arguments': Scope contains method arguments.
   * 'locals': Scope contains local variables.
   * 'registers': Scope contains registers. Only a single `registers` scope
   * should be returned from a `scopes` request.
   * etc.
   */
  presentationHint?: string;

  /**
   * The variables of this scope can be retrieved by passing the value of
   * `variablesReference` to the `variables` request as long as execution
   * remains suspended. See 'Lifetime of Object References' in the Overview
   * section for details.
   */
  variablesReference: int64;

  /**
   * The number of named variables in this scope.
   * The client can use this information to present the variables in a paged UI
   * and fetch them in chunks.
   */
  namedVariables?: number;

  /**
   * The number of indexed variables in this scope.
   * The client can use this information to present the variables in a paged UI
   * and fetch them in chunks.
   */
  indexedVariables?: number;

  /**
   * If true, the number of variables in this scope is large or expensive to
   * retrieve.
   */
  expensive: boolean;

  /**
   * The source for this scope.
   */
  source?: Source;

  /**
   * The start line of the range covered by this scope.
   */
  line?: number;

  /**
   * Start position of the range covered by the scope. It is measured in UTF-16
   * code units and the client capability `columnsStartAt1` determines whether
   * it is 0- or 1-based.
   */
  column?: number;

  /**
   * The end line of the range covered by this scope.
   */
  endLine?: number;

  /**
   * End position of the range covered by the scope. It is measured in UTF-16
   * code units and the client capability `columnsStartAt1` determines whether
   * it is 0- or 1-based.
   */
  endColumn?: number;
}

interface ScopeResponseBody {
  /**
   * The scopes of the stack frame. If the array has length zero, there are no
   * scopes available.
   */
  scopes: Scope[];
}

interface ScopeResponse extends Response {
  body: ScopeResponseBody;
}

interface VariablesArguments {
  /**
   * The variable for which to retrieve its children. The `variablesReference`
   * must have been obtained in the current suspended state. See 'Lifetime of
   * Object References' in the Overview section for details.
   */
  variablesReference: int64;

  /**
   * Filter to limit the child variables to either named or indexed. If omitted,
   * both types are fetched.
   * Values: 'indexed', 'named'
   */
  filter?: string;

  /**
   * The index of the first variable to return; if omitted children start at 0.
   */
  start?: int64;

  /**
   * The number of variables to return. If count is missing or 0, all variables
   * are returned.
   */
  count?: int64;

  /**
   * Specifies details on how to format the Variable values.
   * The attribute is only honored by a debug adapter if the corresponding
   * capability `supportsValueFormattingOptions` is true.
   */
  format?: ValueFormat;
}

interface VariablesRequest extends Request {
  command: 'variables';

  arguments: VariablesArguments;
}

interface Variable {
  /**
   * The variable's name.
   */
  name: string;

  /**
   * The variable's value.
   * This can be a multi-line text, e.g. for a function the body of a function.
   * For structured variables (which do not have a simple value), it is
   * recommended to provide a one-line representation of the structured object.
   * This helps to identify the structured object in the collapsed state when
   * its children are not yet visible.
   * An empty string can be used if no value should be shown in the UI.
   */
  value: string;

  /**
   * The type of the variable's value. Typically shown in the UI when hovering
   * over the value.
   * This attribute should only be returned by a debug adapter if the
   * corresponding capability `supportsVariableType` is true.
   */
  type?: string;

  /**
   * Properties of a variable that can be used to determine how to render the
   * variable in the UI.
   */
  presentationHint?: VariablePresentationHint;

  /**
   * The evaluatable name of this variable which can be passed to the `evaluate`
   * request to fetch the variable's value.
   */
  evaluateName?: string;

  /**
   * If `variablesReference` is > 0, the variable is structured and its children
   * can be retrieved by passing `variablesReference` to the `variables` request
   * as long as execution remains suspended. See 'Lifetime of Object References'
   * in the Overview section for details.
   */
  variablesReference: int64;

  /**
   * The number of named child variables.
   * The client can use this information to present the children in a paged UI
   * and fetch them in chunks.
   */
  namedVariables?: number;

  /**
   * The number of indexed child variables.
   * The client can use this information to present the children in a paged UI
   * and fetch them in chunks.
   */
  indexedVariables?: number;

  /**
   * The memory reference for the variable if the variable represents executable
   * code, such as a function pointer.
   * This attribute is only required if the corresponding capability
   * `supportsMemoryReferences` is true.
   */
  memoryReference?: string;
}


interface VariablesResponseBody {
  /**
   * All (or a range) of variables for the given variable reference.
   */
  variables: Variable[];
}

interface VariablesResponse extends Response {
  body: VariablesResponseBody;
}

interface ThreadEventBody {
  /**
   * The reason for the event.
   * Values: 'started', 'exited', etc.
   */
  reason: string;

  /**
   * The identifier of the thread.
   */
  threadId: int64;
}

interface ThreadEvent extends Event {
  event: 'thread';

  body: ThreadEventBody;
}