/*
 * All content copyright Terracotta, Inc., unless otherwise indicated. All rights reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
module hunt.quartz.impl.DefaultThreadExecutor;

import hunt.quartz.spi.ThreadExecutor;
import core.thread;

/**
 * Schedules work on a newly spawned thread. This is the default Quartz
 * behavior.
 *
 * @author matt.accola
 * @version $Revision$ $LocalDateTime$
 */
class DefaultThreadExecutor : ThreadExecutor {

    void initialize() {
    }

    void execute(Thread thread) {
        thread.start();
    }

}
