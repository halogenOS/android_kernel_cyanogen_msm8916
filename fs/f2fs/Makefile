CFLAGS_KERNEL := -fno-graphite \
          	-fno-graphite-identity \
          	-fno-loop-flatten \
          	-fno-tree-loop-linear \
          	-fno-loop-interchange \
          	-fno-loop-strip-mine \
          	-fno-loop-block \
          	-fno-loop-nest-optimize \
          	-fno-loop-unroll-and-jam \
          	-fno-loop-parallelize-all \
          	-ftree-parallelize-loops=0 \
          	-fno-openmp \
		-Wno-unused-function

obj-$(CONFIG_F2FS_FS) += f2fs.o

f2fs-y		:= dir.o file.o inode.o namei.o hash.o super.o inline.o
f2fs-y		+= checkpoint.o gc.o data.o node.o segment.o recovery.o
f2fs-y		+= shrinker.o extent_cache.o
f2fs-$(CONFIG_F2FS_STAT_FS) += debug.o
f2fs-$(CONFIG_F2FS_FS_XATTR) += xattr.o
f2fs-$(CONFIG_F2FS_FS_POSIX_ACL) += acl.o
f2fs-$(CONFIG_F2FS_IO_TRACE) += trace.o
