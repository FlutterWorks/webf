/*
 * Copyright (C) 2011 Google Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *
 *     * Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above
 * copyright notice, this list of conditions and the following disclaimer
 * in the documentation and/or other materials provided with the
 * distribution.
 *     * Neither the name of Google Inc. nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/*
 * Copyright (C) 2022-present The WebF authors. All rights reserved.
 */

#include "mutation_observer_interest_group.h"
#include "bindings/qjs/cppgc/member.h"
#include "node.h"

namespace webf {

std::shared_ptr<MutationObserverInterestGroup> MutationObserverInterestGroup::CreateIfNeeded(
    Node& target,
    MutationType type,
    MutationRecordDeliveryOptions old_value_flag,
    const AtomicString* attribute_name) {
  assert((type == kMutationTypeAttributes && attribute_name) || !attribute_name);
  MutationObserverOptionsMap observers;
  target.GetRegisteredMutationObserversOfType(observers, type, attribute_name);
  if (observers.empty())
    return nullptr;

  return std::make_shared<MutationObserverInterestGroup>(observers, old_value_flag);
}

MutationObserverInterestGroup::MutationObserverInterestGroup(MutationObserverOptionsMap& observers,
                                                             webf::MutationRecordDeliveryOptions old_value_flag)
    : old_value_flag_(old_value_flag) {
  assert(!observers.empty());
  observers_.swap(observers);
}

MutationObserverInterestGroup::~MutationObserverInterestGroup() {}

bool MutationObserverInterestGroup::IsOldValueRequested() {
  for (auto& observer : observers_) {
    if (HasOldValue(observer.second))
      return true;
  }
  return false;
}

void MutationObserverInterestGroup::EnqueueMutationRecord(MutationRecord* mutation) {
  MutationRecord* mutation_with_null_old_value = nullptr;

  for (auto& iter : observers_) {
    MutationObserver* observer = iter.first;
    if (HasOldValue(iter.second)) {
      observer->EnqueueMutationRecord(mutation);
      continue;
    }
    if (!mutation_with_null_old_value) {
      if (mutation->oldValue().IsNull())
        mutation_with_null_old_value = mutation;
      else
        mutation_with_null_old_value = MutationRecord::CreateWithNullOldValue(mutation);
    }
    observer->EnqueueMutationRecord(mutation_with_null_old_value);
  }
}

void MutationObserverInterestGroup::Trace(GCVisitor* visitor) const {}

}  // namespace webf
