/*
 * Copyright (C) 2021 Alibaba Inc. All rights reserved.
 * Author: Kraken Team.
 */

#ifndef KRAKENBRIDGE_CONTEXT_DATA_H
#define KRAKENBRIDGE_CONTEXT_DATA_H

#include <unordered_map>
#include "wrapper_type_info.h"

namespace kraken::binding::qjs {

class ExecutionContext;

// Used to hold data that is associated with a single ExecutionContext object, and
// has a 1:1 relationship with ExecutionContext.
class ExecutionContextData final {
 public:
  explicit ExecutionContextData(ExecutionContext* context): m_context(context) {};
  ExecutionContextData(const ExecutionContextData&) = delete;
  ExecutionContextData& operator=(const ExecutionContextData&) = delete;

  // Returns the constructor object that is appropriately initialized.
  JSValue constructorForType(const WrapperTypeInfo* type);
  // Returns the prototype object that is appropriately initialized.
  JSValue prototypeForType(const WrapperTypeInfo* type);

 private:
  JSValue constructorForIdSlowCase(const WrapperTypeInfo* type);
  std::unordered_map<const WrapperTypeInfo*, JSValue> m_constructorMap;
  std::unordered_map<const WrapperTypeInfo*, JSValue> m_prototypeMap;

  ExecutionContext* m_context;
};


}

#endif  // KRAKENBRIDGE_CONTEXT_DATA_H