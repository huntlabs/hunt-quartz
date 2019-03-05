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
module hunt.quartz.utils.ClassUtils;

// import java.lang.annotation.Annotation;
// import java.util.Arrays;
// import hunt.collection.LinkedList;
// import java.util.Queue;

// class ClassUtils {

    
//     static bool isAnnotationPresent(TypeInfo_Class clazz, Class<? extends Annotation> a) {
//         for (TypeInfo_Class c = clazz; c !is null; c = c.getSuperclass()) {
//             if (c.isAnnotationPresent(a))
//                 return true;
//             if(isAnnotationPresentOnInterfaces(c, a))
//                 return true;
//         }
//         return false;
//     }

//     private static bool isAnnotationPresentOnInterfaces(TypeInfo_Class clazz, Class<? extends Annotation> a) {
//         foreach(TypeInfo_Class i ; clazz.getInterfaces()) {
//             if( i.isAnnotationPresent(a) )
//                 return true;
//             if(isAnnotationPresentOnInterfaces(i, a))
//                 return true;
//         }
        
//         return false;
//     }

//     static <T extends Annotation> T getAnnotation(TypeInfo_Class clazz, Class!(T) aClazz) {
//         //Check class hierarchy
//         for (TypeInfo_Class c = clazz; c !is null; c = c.getSuperclass()) {
//             T anno = c.getAnnotation(aClazz);
//             if (anno !is null) {
//                 return anno;
//             }
//         }

//         //Check interfaces (breadth first)
//         Queue!(TypeInfo_Class) q = new LinkedList!(TypeInfo_Class)();
//         q.add(clazz);
//         while (!q.isEmpty()) {
//             TypeInfo_Class c = q.remove();
//             if (c !is null) {
//                 if (c.isInterface()) {
//                     T anno = c.getAnnotation(aClazz);
//                     if (anno !is null) {
//                         return anno;
//                     }
//                 } else {
//                     q.add(c.getSuperclass());
//                 }
//                 q.addAll(Arrays.asList(c.getInterfaces()));
//             }
//         }

//         return null;
//     }
// }
