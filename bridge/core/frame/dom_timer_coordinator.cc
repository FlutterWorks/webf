/*
 * Copyright (C) 2021 Alibaba Inc. All rights reserved.
 * Author: Kraken Team.
 */

#include "dom_timer_coordinator.h"
#include "core/dart_methods.h"
#include "core/executing_context.h"
#include "dom_timer.h"

#if UNIT_TEST
#include "kraken_test_env.h"
#endif

namespace kraken {

static void handleTimerCallback(DOMTimer* timer, const char* errmsg) {
  auto* context = timer->context();

  if (errmsg != nullptr) {
    JSValue exception = JS_ThrowTypeError(timer->context()->ctx(), "%s", errmsg);
    context->HandleException(&exception);
    return;
  }

  // Trigger timer callbacks.
  timer->Fire();

  // Executing pending async jobs.
  context->DrainPendingPromiseJobs();
}

static void handleTransientCallback(void* ptr, int32_t contextId, const char* errmsg) {
  auto* timer = static_cast<DOMTimer*>(ptr);
  auto* context = timer->context();

  if (!context->IsValid())
    return;

  handleTimerCallback(timer, errmsg);

  context->Timers()->removeTimeoutById(timer->timerId());
}

void DOMTimerCoordinator::installNewTimer(ExecutingContext* context, int32_t timerId, DOMTimer* timer) {
  m_activeTimers[timerId] = timer;
}

void* DOMTimerCoordinator::removeTimeoutById(int32_t timerId) {
  if (m_activeTimers.count(timerId) == 0)
    return nullptr;
  DOMTimer* timer = m_activeTimers[timerId];

  // Push this timer to abandoned list to mark this timer is deprecated.
  m_abandonedTimers.emplace_back(timer);

  m_activeTimers.erase(timerId);
  return nullptr;
}

DOMTimer* DOMTimerCoordinator::getTimerById(int32_t timerId) {
  if (m_activeTimers.count(timerId) == 0)
    return nullptr;
  return m_activeTimers[timerId];
}

void DOMTimerCoordinator::trace(GCVisitor* visitor) {
  for (auto& timer : m_activeTimers) {
    timer.second->Trace(visitor);
  }

  // Recycle all abandoned timers.
  if (!m_abandonedTimers.empty()) {
    for (auto& timer : m_abandonedTimers) {
      timer->Trace(visitor);
    }
    // All abandoned timers should be freed at the sweep stage.
    m_abandonedTimers.clear();
  }
}

}  // namespace kraken