import numpy as np
cimport numpy as np

# python setup_computeind.py build_ext --inplace
# cython -a computeind.pyx

DTYPE = np.int
ctypedef np.int_t DTYPE_t
ctypedef unsigned int ITYPE_t
cimport cython
@cython.boundscheck(False)
def compute_ind(np.ndarray[DTYPE_t, ndim=1] nums,
                ITYPE_t map_dofs1,
                ITYPE_t lins1,
                DTYPE_t layers1,
                np.ndarray[DTYPE_t, ndim=1] mesh2d,
                np.ndarray[DTYPE_t, ndim=2] dofs not None,
                A not None,
                ITYPE_t wedges1,
                mapp,
                ITYPE_t lsize):
  cdef unsigned int count = 0
  cdef DTYPE_t m
  cdef unsigned int c,offset
  cdef DTYPE_t layers = layers1
  cdef unsigned int map_dofs = <unsigned int>map_dofs1
  cdef unsigned int wedges = <unsigned int>wedges1
  cdef unsigned int lins = <unsigned int>lins1
  cdef unsigned int mm,d,i,j,k,l
  cdef np.ndarray[DTYPE_t, ndim=1] ind = np.zeros(lsize, dtype=DTYPE)
  cdef DTYPE_t a1,a2,a3
  cdef int a4
  cdef int len1 = len(mesh2d)
  cdef int len2



  for mm in range(0,lins):
    offset = 0
    for d in range(0,2):
      c = 0
      for i in range(0,len1):
        a4 = dofs[i, d]
        if a4 != 0:
          len2 = len(A[d])
          for j in range(0, mesh2d[i]):
            m = mapp[mm][c]
            for k in range(0, len2):
              a3 = <DTYPE_t>A[d][k]*a4
              for l in range(0,wedges):
                    ind[count + l * nums[2]*a4*mesh2d[i]] = l + m*a4*(layers - d) + a3 + offset
              count+=1
                    #ind[count + l * a4 * mesh2d[i]] = l + m*a4*(layers - d) + a3 + offset
              #count+=1
            c+=1
          #count+= (wedges-d-1)*a4*mesh2d[i]
        elif dofs[i, 1-d] != 0:
          c+= <unsigned int>mesh2d[i]
        offset += a4*nums[i]*(layers - d)
  return ind


@cython.boundscheck(False)
def compute_ind_extr(np.ndarray[DTYPE_t, ndim=1] nums,
                ITYPE_t map_dofs1,
                ITYPE_t lins1,
                DTYPE_t layers1,
                np.ndarray[DTYPE_t, ndim=1] mesh2d,
                np.ndarray[DTYPE_t, ndim=2] dofs not None,
                A not None,
                ITYPE_t wedges1,
                mapp,
                ITYPE_t lsize):
  cdef unsigned int count = 0
  cdef DTYPE_t m
  cdef unsigned int c,offset
  cdef DTYPE_t layers = layers1
  cdef unsigned int map_dofs = <unsigned int>map_dofs1
  cdef unsigned int wedges = <unsigned int>wedges1
  cdef unsigned int lins = <unsigned int>lins1
  cdef unsigned int mm,d,i,j,k,l
  cdef np.ndarray[DTYPE_t, ndim=1] ind = np.zeros(lsize, dtype=DTYPE)
  cdef DTYPE_t a1,a2,a3
  cdef int a4
  cdef int len1 = len(mesh2d)
  cdef int len2


  for mm in range(0,lins):
    offset = 0
    for d in range(0,2):
      c = 0
      for i in range(0,len1):
        a4 = dofs[i, d]
        if a4 != 0:
          len2 = len(A[d])
          for j in range(0, mesh2d[i]):
            m = mapp[mm][c]
            for k in range(0, len2):
              ind[count] = m*(layers - d) + <DTYPE_t>A[d][k] + offset
              count+=1
            c+=1
        elif dofs[i, 1-d] != 0:
          c+= <unsigned int>mesh2d[i]
        offset += a4*nums[i]*(layers - d)
  return ind

@cython.boundscheck(False)
def swap_ind_entries(np.ndarray[DTYPE_t, ndim=1] ind,
                    ITYPE_t k,
                    ITYPE_t map_dofs,
                    ITYPE_t lsize,
                    ITYPE_t ahead,
                    np.ndarray[int, ndim=1] my_cache,
                    ITYPE_t same):
  cdef unsigned int change = 0
  cdef unsigned int found = 0
  cdef unsigned int i,j,m,l,n
  cdef unsigned int pos = 0
  cdef unsigned int swaps = 0
  for i in range(k*map_dofs,lsize,map_dofs):
    lim = 0
    for j in range(i,lsize,map_dofs):
        if lim < ahead:
            found = 0
            for m in range(0,map_dofs):
                look_for = ind[j + m]
                #look for value in the cache
                change = 0
                for l in range(0,k):
                    for n in range(0,map_dofs):
                        if ind[my_cache[l] + n] == look_for:
                            found+=1
                            change+=1
                            break
                    if change == 1:
                        break
            if found >= same:
                #found a candidate so swap
                for n in range(0,map_dofs):
                    swaps+=1
                    aux = ind[j + n]
                    ind[j + n] = ind[i + n]
                    ind[i+n] = aux

                my_cache[pos] = j
                pos += 1
                if pos == k:
                    pos = 0
                break
        else:
            my_cache[pos] = i
            pos += 1
            if pos == k:
                pos = 0
            break
        lim += 1
  print "swaps = %d" % swaps
  return ind

@cython.boundscheck(False)
def swap_ind_entries_batch(np.ndarray[DTYPE_t, ndim=1] ind,
                    ITYPE_t k,
                    ITYPE_t map_dofs,
                    ITYPE_t lsize,
                    ITYPE_t ahead,
                    np.ndarray[int, ndim=1] my_cache,
                    ITYPE_t same):
  cdef unsigned int sw = 0 + map_dofs
  cdef unsigned int found = 0
  cdef unsigned int i,j,m,l,n
  cdef unsigned int pos = 0
  cdef unsigned int swaps = 0
  for i in range(0, lsize, map_dofs):
    sw = i + map_dofs
    pos = 0
    for j in range(i+map_dofs, lsize, map_dofs):
            found = 0
            for m in range(0,map_dofs):
                look_for = ind[j + m]
                for n in range(0, map_dofs):
                    if ind[i + n] == look_for:
                            found += 1
                            break

            if found >= same:
                #found a candidate so swap
                swaps += 1
                pos += 1

                #if sw < 20*6:
                #    ssw = sw / 6
                #    jj = j / 6
                #    print "swap to %d the ind at" % ssw
                #    print "----------------------> %d " % jj
                #    print ind[i:i+map_dofs], ind[j:j+map_dofs]

                for n in range(0, map_dofs):
                    aux = ind[j + n]
                    ind[j + n] = ind[sw + n]
                    ind[sw + n] = aux
                sw += map_dofs
    #if sw < 120:
    #    print "done triangle"
    #if swaps < 1000:
    #    print "swaps = %d" % swaps
    i += pos * map_dofs
  print "swaps = %d" % swaps
  return ind

#cdef data_to_numpy_array_with_spec(void * ptr, np.npy_intp size, int t):
#    """Return an array of SIZE elements (each of type T) with data from PTR."""
#    return np.PyArray_SimpleNewFromData(1, &size, t, ptr)

#cdef ext
#def compute_ind2(nums,map_dofs,lins,layers,mesh2d,dofs,A,wedges,mapp,lsize):
#    cdef int *ind_data
#    compute_ind_function(nums, map_dofs, lins, layers, mesh2d, dofs, &ind_data)
#    return data_to_numpy_array_with_spec(ind_data, lsize, np.NPY_INT32)