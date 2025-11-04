#!/bin/bash
# Create remaining ViewModel documentation files

cd "C:\Users\chris_3zal3ta\documents\ArcheryApprentice-Docs\content\developer-guide\technical-reference\api\viewmodels"

# Equipment ViewModels (similar pattern)
for vm in bow-setup arrow-setup sight-configuration rest-configuration stabilizer-configuration plunger-configuration tab-configuration release-aid-configuration clicker-configuration string-configuration limbs-configuration riser-configuration; do
  if [ ! -f "${vm}-view-model.md" ]; then
    echo "Creating ${vm}-view-model.md"
  fi
done
