module hunt.quartz.spi.TriggerFiredResult;

import hunt.quartz.spi.TriggerFiredBundle;

import std.exception;

/**
 * @author lorban
 */
class TriggerFiredResult {

  private TriggerFiredBundle triggerFiredBundle;

  private Exception exception;

  this(TriggerFiredBundle triggerFiredBundle) {
    this.triggerFiredBundle = triggerFiredBundle;
  }

  this(Exception exception) {
    this.exception = exception;
  }

  TriggerFiredBundle getTriggerFiredBundle() {
    return triggerFiredBundle;
  }

  Exception getException() {
    return exception;
  }
}
